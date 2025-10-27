-- FIX: Corriger les politiques RLS avec récursion infinie

-- ============================================
-- 1. TEAM_USERDATA - Simplifier les politiques
-- ============================================

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view team memberships for their teams" ON "team_userdata";
DROP POLICY IF EXISTS "Users can join teams" ON "team_userdata";
DROP POLICY IF EXISTS "Team owners can update memberships" ON "team_userdata";
DROP POLICY IF EXISTS "Users can leave teams or owners can remove" ON "team_userdata";

-- Nouvelles politiques SANS récursion
CREATE POLICY "Users can view their own memberships" 
ON "team_userdata" 
FOR SELECT 
USING (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

CREATE POLICY "Users can view memberships of their teams" 
ON "team_userdata" 
FOR SELECT 
USING (
    team_id IN (
        SELECT DISTINCT tu.team_id 
        FROM "team_userdata" tu
        INNER JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status IN ('member', 'owner')
    )
);

CREATE POLICY "Users can join teams themselves" 
ON "team_userdata" 
FOR INSERT 
WITH CHECK (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

CREATE POLICY "Users can update their own membership" 
ON "team_userdata" 
FOR UPDATE 
USING (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

CREATE POLICY "Team owners can update any membership" 
ON "team_userdata" 
FOR UPDATE 
USING (
    team_id IN (
        SELECT DISTINCT tu.team_id 
        FROM "team_userdata" tu
        INNER JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status = 'owner'
    )
);

CREATE POLICY "Users can delete their own membership" 
ON "team_userdata" 
FOR DELETE 
USING (
    userdata_id IN (SELECT id FROM "UserDatas" WHERE auth_id = auth.uid())
);

CREATE POLICY "Team owners can delete any membership" 
ON "team_userdata" 
FOR DELETE 
USING (
    team_id IN (
        SELECT DISTINCT tu.team_id 
        FROM "team_userdata" tu
        INNER JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status = 'owner'
    )
);

-- ============================================
-- 2. TEAMS - Simplifier les politiques
-- ============================================

DROP POLICY IF EXISTS "Anyone can view public teams" ON "Teams";
DROP POLICY IF EXISTS "Members can view their private teams" ON "Teams";

-- Politique unique et simple pour la lecture
CREATE POLICY "Users can view teams" 
ON "Teams" 
FOR SELECT 
USING (
    privacy = false  -- Tous les groupes publics
    OR
    id IN (  -- Ou les groupes privés dont on est membre
        SELECT DISTINCT tu.team_id 
        FROM "team_userdata" tu
        INNER JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
    )
);

-- ============================================
-- 3. PRONOS - Simplifier les politiques
-- ============================================

DROP POLICY IF EXISTS "Anyone can view public pronos" ON "Pronos";

CREATE POLICY "Users can view pronos" 
ON "Pronos" 
FOR SELECT 
USING (
    team_id IS NULL  -- Paris publics
    OR
    team_id IN (  -- Paris de leurs groupes
        SELECT DISTINCT tu.team_id 
        FROM "team_userdata" tu
        INNER JOIN "UserDatas" ud ON tu.userdata_id = ud.id
        WHERE ud.auth_id = auth.uid()
        AND tu.status IN ('member', 'owner')
    )
);

-- ============================================
-- 4. BETS - Simplifier les politiques
-- ============================================

DROP POLICY IF EXISTS "Users can view bets if they can view the prono" ON "Bets";

CREATE POLICY "Users can view bets" 
ON "Bets" 
FOR SELECT 
USING (
    prono_id IN (
        SELECT id FROM "Pronos" 
        WHERE team_id IS NULL  -- Paris publics
        OR team_id IN (  -- Paris de leurs groupes
            SELECT DISTINCT tu.team_id 
            FROM "team_userdata" tu
            INNER JOIN "UserDatas" ud ON tu.userdata_id = ud.id
            WHERE ud.auth_id = auth.uid()
            AND tu.status IN ('member', 'owner')
        )
    )
);

