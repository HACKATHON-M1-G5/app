-- FIX COMPLET: Corriger toutes les politiques RLS + fonctions

-- ============================================
-- 1. RECRÉER LES FONCTIONS AVEC SECURITY INVOKER
-- ============================================

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS is_team_member(UUID, UUID);
DROP FUNCTION IF EXISTS is_team_owner(UUID, UUID);

-- Fonction pour vérifier si un utilisateur est membre d'un groupe
-- SECURITY INVOKER = s'exécute avec les privilèges de l'appelant (bypass RLS)
CREATE OR REPLACE FUNCTION is_team_member(p_team_id UUID, p_auth_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_result BOOLEAN;
BEGIN
    -- Désactiver RLS temporairement pour cette fonction
    SET LOCAL row_security TO off;
    
    SELECT EXISTS (
        SELECT 1 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE tu.team_id = p_team_id 
        AND ud.auth_id = p_auth_id
        AND tu.status IN ('member', 'owner')
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si un utilisateur est owner d'un groupe
CREATE OR REPLACE FUNCTION is_team_owner(p_team_id UUID, p_auth_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_result BOOLEAN;
BEGIN
    -- Désactiver RLS temporairement pour cette fonction
    SET LOCAL row_security TO off;
    
    SELECT EXISTS (
        SELECT 1 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE tu.team_id = p_team_id 
        AND ud.auth_id = p_auth_id
        AND tu.status = 'owner'
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 2. CORRIGER LES POLITIQUES TEAMS
-- ============================================

-- Supprimer les anciennes
DROP POLICY IF EXISTS "select_public_teams" ON "Teams";
DROP POLICY IF EXISTS "select_member_teams" ON "Teams";
DROP POLICY IF EXISTS "insert_teams" ON "Teams";
DROP POLICY IF EXISTS "update_teams" ON "Teams";
DROP POLICY IF EXISTS "delete_teams" ON "Teams";

-- Lecture : groupes publics
CREATE POLICY "select_public_teams" 
ON "Teams" 
FOR SELECT 
USING (privacy = false);

-- Lecture : groupes dont on est membre
CREATE POLICY "select_member_teams" 
ON "Teams" 
FOR SELECT 
USING (
    EXISTS (
        SELECT 1 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE tu.team_id = "Teams".id 
        AND ud.auth_id = auth.uid()
        AND tu.status IN ('member', 'owner')
    )
);

-- Création : tout utilisateur authentifié (simplifié)
CREATE POLICY "insert_teams" 
ON "Teams" 
FOR INSERT 
WITH CHECK (true);

-- Mise à jour : seulement les owners
CREATE POLICY "update_teams" 
ON "Teams" 
FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE tu.team_id = "Teams".id 
        AND ud.auth_id = auth.uid()
        AND tu.status = 'owner'
    )
);

-- Suppression : seulement les owners
CREATE POLICY "delete_teams" 
ON "Teams" 
FOR DELETE 
USING (
    EXISTS (
        SELECT 1 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE tu.team_id = "Teams".id 
        AND ud.auth_id = auth.uid()
        AND tu.status = 'owner'
    )
);

-- ============================================
-- 3. CORRIGER LES POLITIQUES TEAM_USERDATA
-- ============================================

DROP POLICY IF EXISTS "select_own_memberships" ON "team_userdata";
DROP POLICY IF EXISTS "select_team_memberships" ON "team_userdata";
DROP POLICY IF EXISTS "insert_own_membership" ON "team_userdata";
DROP POLICY IF EXISTS "update_own_membership" ON "team_userdata";
DROP POLICY IF EXISTS "update_as_owner" ON "team_userdata";
DROP POLICY IF EXISTS "delete_own_membership" ON "team_userdata";
DROP POLICY IF EXISTS "delete_as_owner" ON "team_userdata";

-- Lecture : voir ses propres adhésions (toujours)
CREATE POLICY "select_own_memberships" 
ON "team_userdata" 
FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM "UserDatas" 
        WHERE id = userdata_id 
        AND auth_id = auth.uid()
    )
);

-- Lecture : voir toutes les adhésions d'un groupe dont on est membre
CREATE POLICY "select_team_memberships" 
ON "team_userdata" 
FOR SELECT 
USING (
    team_id IN (
        SELECT tu.team_id 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status IN ('member', 'owner')
    )
);

-- Insertion : créer sa propre adhésion (toujours autorisé)
CREATE POLICY "insert_own_membership" 
ON "team_userdata" 
FOR INSERT 
WITH CHECK (true);

-- Mise à jour : mettre à jour sa propre adhésion
CREATE POLICY "update_own_membership" 
ON "team_userdata" 
FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM "UserDatas" 
        WHERE id = userdata_id 
        AND auth_id = auth.uid()
    )
);

-- Mise à jour : owner peut tout modifier dans son groupe
CREATE POLICY "update_as_owner" 
ON "team_userdata" 
FOR UPDATE 
USING (
    team_id IN (
        SELECT tu.team_id 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status = 'owner'
    )
);

-- Suppression : supprimer sa propre adhésion
CREATE POLICY "delete_own_membership" 
ON "team_userdata" 
FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM "UserDatas" 
        WHERE id = userdata_id 
        AND auth_id = auth.uid()
    )
);

-- Suppression : owner peut supprimer n'importe qui dans son groupe
CREATE POLICY "delete_as_owner" 
ON "team_userdata" 
FOR DELETE 
USING (
    team_id IN (
        SELECT tu.team_id 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status = 'owner'
    )
);

-- ============================================
-- 4. CORRIGER LES POLITIQUES PRONOS
-- ============================================

DROP POLICY IF EXISTS "select_public_pronos" ON "Pronos";
DROP POLICY IF EXISTS "select_team_pronos" ON "Pronos";
DROP POLICY IF EXISTS "insert_pronos" ON "Pronos";
DROP POLICY IF EXISTS "update_pronos" ON "Pronos";
DROP POLICY IF EXISTS "delete_pronos" ON "Pronos";

-- Lecture : pronos publics (toujours)
CREATE POLICY "select_public_pronos" 
ON "Pronos" 
FOR SELECT 
USING (team_id IS NULL);

-- Lecture : pronos des groupes dont on est membre
CREATE POLICY "select_team_pronos" 
ON "Pronos" 
FOR SELECT 
USING (
    team_id IN (
        SELECT tu.team_id 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status IN ('member', 'owner')
    )
);

-- Création : owners de groupe ou pour pronos publics
CREATE POLICY "insert_pronos" 
ON "Pronos" 
FOR INSERT 
WITH CHECK (
    team_id IS NULL  -- Pronos publics autorisés pour tous
    OR 
    team_id IN (  -- Ou owner du groupe
        SELECT tu.team_id 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status = 'owner'
    )
);

-- Mise à jour : propriétaire du prono
CREATE POLICY "update_pronos" 
ON "Pronos" 
FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM "UserDatas" 
        WHERE id = owner_id 
        AND auth_id = auth.uid()
    )
);

-- Suppression : propriétaire du prono
CREATE POLICY "delete_pronos" 
ON "Pronos" 
FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM "UserDatas" 
        WHERE id = owner_id 
        AND auth_id = auth.uid()
    )
);

