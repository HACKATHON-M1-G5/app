-- FIX DÉFINITIF : Politiques RLS ultra-simplifiées sans aucune récursion

-- ============================================
-- 1. DÉSACTIVER TEMPORAIREMENT RLS
-- ============================================

ALTER TABLE "team_userdata" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "Teams" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "Pronos" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "Bets" DISABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
-- ============================================

-- team_userdata
DROP POLICY IF EXISTS "Users can view team memberships for their teams" ON "team_userdata";
DROP POLICY IF EXISTS "Users can join teams" ON "team_userdata";
DROP POLICY IF EXISTS "Team owners can update memberships" ON "team_userdata";
DROP POLICY IF EXISTS "Users can leave teams or owners can remove" ON "team_userdata";
DROP POLICY IF EXISTS "Users can view their own memberships" ON "team_userdata";
DROP POLICY IF EXISTS "Users can view memberships of their teams" ON "team_userdata";
DROP POLICY IF EXISTS "Users can join teams themselves" ON "team_userdata";
DROP POLICY IF EXISTS "Users can update their own membership" ON "team_userdata";
DROP POLICY IF EXISTS "Team owners can update any membership" ON "team_userdata";
DROP POLICY IF EXISTS "Users can delete their own membership" ON "team_userdata";
DROP POLICY IF EXISTS "Team owners can delete any membership" ON "team_userdata";

-- Teams
DROP POLICY IF EXISTS "Anyone can view public teams" ON "Teams";
DROP POLICY IF EXISTS "Members can view their private teams" ON "Teams";
DROP POLICY IF EXISTS "Authenticated users can create teams" ON "Teams";
DROP POLICY IF EXISTS "Team owners can update teams" ON "Teams";
DROP POLICY IF EXISTS "Team owners can delete teams" ON "Teams";
DROP POLICY IF EXISTS "Users can view teams" ON "Teams";

-- Pronos
DROP POLICY IF EXISTS "Anyone can view public pronos" ON "Pronos";
DROP POLICY IF EXISTS "Team owners can create pronos" ON "Pronos";
DROP POLICY IF EXISTS "Prono owners can update pronos" ON "Pronos";
DROP POLICY IF EXISTS "Prono owners can delete pronos" ON "Pronos";
DROP POLICY IF EXISTS "Users can view pronos" ON "Pronos";

-- Bets
DROP POLICY IF EXISTS "Users can view bets if they can view the prono" ON "Bets";
DROP POLICY IF EXISTS "Prono owners can create bets" ON "Bets";
DROP POLICY IF EXISTS "Prono owners can update bets" ON "Bets";
DROP POLICY IF EXISTS "Prono owners can delete bets" ON "Bets";
DROP POLICY IF EXISTS "Users can view bets" ON "Bets";

-- ============================================
-- 3. CRÉER UNE FONCTION HELPER (pas de récursion)
-- ============================================

-- Fonction pour vérifier si un utilisateur est membre d'un groupe
CREATE OR REPLACE FUNCTION is_team_member(p_team_id UUID, p_auth_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE tu.team_id = p_team_id 
        AND ud.auth_id = p_auth_id
        AND tu.status IN ('member', 'owner')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si un utilisateur est owner d'un groupe
CREATE OR REPLACE FUNCTION is_team_owner(p_team_id UUID, p_auth_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM "team_userdata" tu
        JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE tu.team_id = p_team_id 
        AND ud.auth_id = p_auth_id
        AND tu.status = 'owner'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. TEAM_USERDATA - Politiques ultra-simples
-- ============================================

-- Lecture : voir ses propres adhésions
CREATE POLICY "select_own_memberships" 
ON "team_userdata" 
FOR SELECT 
USING (
    userdata_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

-- Lecture : voir les adhésions des groupes dont on est membre (via fonction)
CREATE POLICY "select_team_memberships" 
ON "team_userdata" 
FOR SELECT 
USING (
    is_team_member(team_id, auth.uid())
);

-- Insertion : créer sa propre adhésion
CREATE POLICY "insert_own_membership" 
ON "team_userdata" 
FOR INSERT 
WITH CHECK (
    userdata_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

-- Mise à jour : mettre à jour sa propre adhésion
CREATE POLICY "update_own_membership" 
ON "team_userdata" 
FOR UPDATE 
USING (
    userdata_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

-- Mise à jour : owner peut tout modifier
CREATE POLICY "update_as_owner" 
ON "team_userdata" 
FOR UPDATE 
USING (
    is_team_owner(team_id, auth.uid())
);

-- Suppression : supprimer sa propre adhésion
CREATE POLICY "delete_own_membership" 
ON "team_userdata" 
FOR DELETE 
USING (
    userdata_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

-- Suppression : owner peut supprimer n'importe qui
CREATE POLICY "delete_as_owner" 
ON "team_userdata" 
FOR DELETE 
USING (
    is_team_owner(team_id, auth.uid())
);

-- ============================================
-- 5. TEAMS - Politiques simples
-- ============================================

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
    is_team_member(id, auth.uid())
);

-- Création : tout utilisateur authentifié
CREATE POLICY "insert_teams" 
ON "Teams" 
FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL);

-- Mise à jour : seulement les owners
CREATE POLICY "update_teams" 
ON "Teams" 
FOR UPDATE 
USING (
    is_team_owner(id, auth.uid())
);

-- Suppression : seulement les owners
CREATE POLICY "delete_teams" 
ON "Teams" 
FOR DELETE 
USING (
    is_team_owner(id, auth.uid())
);

-- ============================================
-- 6. PRONOS - Politiques simples
-- ============================================

-- Lecture : pronos publics
CREATE POLICY "select_public_pronos" 
ON "Pronos" 
FOR SELECT 
USING (team_id IS NULL);

-- Lecture : pronos des groupes dont on est membre
CREATE POLICY "select_team_pronos" 
ON "Pronos" 
FOR SELECT 
USING (
    team_id IS NOT NULL AND is_team_member(team_id, auth.uid())
);

-- Création : owners de groupe ou pour pronos publics
CREATE POLICY "insert_pronos" 
ON "Pronos" 
FOR INSERT 
WITH CHECK (
    team_id IS NULL OR is_team_owner(team_id, auth.uid())
);

-- Mise à jour : propriétaire du prono
CREATE POLICY "update_pronos" 
ON "Pronos" 
FOR UPDATE 
USING (
    owner_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

-- Suppression : propriétaire du prono
CREATE POLICY "delete_pronos" 
ON "Pronos" 
FOR DELETE 
USING (
    owner_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

-- ============================================
-- 7. BETS - Politiques simples
-- ============================================

-- Lecture : bets des pronos accessibles
CREATE POLICY "select_bets" 
ON "Bets" 
FOR SELECT 
USING (
    prono_id IN (
        SELECT id FROM "Pronos" 
        WHERE team_id IS NULL 
        OR is_team_member(team_id, auth.uid())
    )
);

-- Création : propriétaire du prono
CREATE POLICY "insert_bets" 
ON "Bets" 
FOR INSERT 
WITH CHECK (
    prono_id IN (
        SELECT id FROM "Pronos" 
        WHERE owner_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
    )
);

-- Mise à jour : propriétaire du prono
CREATE POLICY "update_bets" 
ON "Bets" 
FOR UPDATE 
USING (
    prono_id IN (
        SELECT id FROM "Pronos" 
        WHERE owner_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
    )
);

-- Suppression : propriétaire du prono
CREATE POLICY "delete_bets" 
ON "Bets" 
FOR DELETE 
USING (
    prono_id IN (
        SELECT id FROM "Pronos" 
        WHERE owner_id = (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
    )
);

-- ============================================
-- 8. RÉACTIVER RLS
-- ============================================

ALTER TABLE "team_userdata" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Teams" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Pronos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Bets" ENABLE ROW LEVEL SECURITY;

