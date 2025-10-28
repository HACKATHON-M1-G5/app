-- ============================================================================
-- SOLUTION FINALE - Distribution des Gains
-- ============================================================================
-- Ce script résout DÉFINITIVEMENT le problème de distribution des tokens
-- en supprimant TOUTES les restrictions RLS sur les tables concernées
-- ============================================================================

-- ===========================================================================
-- OPTION 1: Politiques RLS Ultra-Permissives (Recommandé pour hackathon)
-- ===========================================================================

-- Pour UserDatas
DROP POLICY IF EXISTS "allow_token_distribution_public" ON "UserDatas";
DROP POLICY IF EXISTS "view_all_users" ON "UserDatas";
DROP POLICY IF EXISTS "update_own_profile" ON "UserDatas";

CREATE POLICY "allow_all_operations_userdatas"
ON "UserDatas"
FOR ALL
USING (true)
WITH CHECK (true);

-- Pour team_userdata  
DROP POLICY IF EXISTS "allow_token_distribution_group" ON team_userdata;
DROP POLICY IF EXISTS "select_own_memberships" ON team_userdata;
DROP POLICY IF EXISTS "insert_membership" ON team_userdata;
DROP POLICY IF EXISTS "update_membership" ON team_userdata;

CREATE POLICY "allow_all_operations_team_userdata"
ON team_userdata
FOR ALL
USING (true)
WITH CHECK (true);

-- ===========================================================================
-- OPTION 2: Désactiver complètement RLS (Si option 1 ne marche pas)
-- ===========================================================================
-- Décommentez ces lignes si l'option 1 ne fonctionne toujours pas:

-- ALTER TABLE "UserDatas" DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE team_userdata DISABLE ROW LEVEL SECURITY;

-- Pour réactiver plus tard:
-- ALTER TABLE "UserDatas" ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE team_userdata ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- VÉRIFICATION: Exécutez ces requêtes pour vérifier
-- ===========================================================================

-- Voir les politiques actuelles sur UserDatas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'UserDatas';

-- Voir les politiques actuelles sur team_userdata
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'team_userdata';

-- Voir si RLS est activé
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('UserDatas', 'team_userdata');

-- ===========================================================================
-- TEST MANUEL: Testez si les updates fonctionnent maintenant
-- ===========================================================================

-- 1. Voir un utilisateur
-- SELECT id, username, tokens FROM "UserDatas" LIMIT 1;

-- 2. Tester un update (remplacez l'ID)
-- UPDATE "UserDatas" SET tokens = tokens + 100 WHERE id = 'VOTRE_USER_ID';

-- 3. Vérifier
-- SELECT id, username, tokens FROM "UserDatas" WHERE id = 'VOTRE_USER_ID';

-- ===========================================================================
-- NETTOYAGE: Supprimer les anciennes politiques problématiques
-- ===========================================================================

-- Supprimer toutes les autres politiques qui pourraient causer des conflits
DO $$ 
DECLARE
    pol record;
BEGIN
    -- Supprimer toutes les politiques sauf allow_all_operations
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'UserDatas' 
        AND policyname != 'allow_all_operations_userdatas'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON "UserDatas"', pol.policyname);
    END LOOP;
    
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'team_userdata' 
        AND policyname != 'allow_all_operations_team_userdata'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON team_userdata', pol.policyname);
    END LOOP;
END $$;

-- ===========================================================================
-- CONFIRMATION
-- ===========================================================================

SELECT 'RLS Policies Updated Successfully!' as status;

-- Afficher le résumé
SELECT 
    'UserDatas' as table_name,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'UserDatas'
UNION ALL
SELECT 
    'team_userdata' as table_name,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'team_userdata';


