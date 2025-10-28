-- ============================================================================
-- FIX - Résoudre les Conflits de Politiques RLS
-- ============================================================================
-- Ce script nettoie toutes les politiques existantes et les recrée proprement
-- Exécutez ce script si vous avez l'erreur "policy already exists"
-- ============================================================================

-- ===========================================================================
-- 1. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES (sans erreur si elles n'existent pas)
-- ===========================================================================

-- Nettoyer UserDatas
DROP POLICY IF EXISTS "allow_all_userdatas" ON "UserDatas";
DROP POLICY IF EXISTS "allow_all_operations_userdatas" ON "UserDatas";
DROP POLICY IF EXISTS "allow_token_distribution_public" ON "UserDatas";
DROP POLICY IF EXISTS "view_all_users" ON "UserDatas";
DROP POLICY IF EXISTS "update_own_profile" ON "UserDatas";
DROP POLICY IF EXISTS "select_own_data" ON "UserDatas";
DROP POLICY IF EXISTS "insert_own_data" ON "UserDatas";
DROP POLICY IF EXISTS "update_own_data" ON "UserDatas";

-- Nettoyer team_userdata
DROP POLICY IF EXISTS "allow_all_team_userdata" ON team_userdata;
DROP POLICY IF EXISTS "allow_all_operations_team_userdata" ON team_userdata;
DROP POLICY IF EXISTS "allow_token_distribution_group" ON team_userdata;
DROP POLICY IF EXISTS "select_own_memberships" ON team_userdata;
DROP POLICY IF EXISTS "insert_membership" ON team_userdata;
DROP POLICY IF EXISTS "update_membership" ON team_userdata;
DROP POLICY IF EXISTS "select_team_memberships" ON team_userdata;
DROP POLICY IF EXISTS "insert_team_membership" ON team_userdata;
DROP POLICY IF EXISTS "update_team_membership" ON team_userdata;

-- ===========================================================================
-- 2. SUPPRIMER DYNAMIQUEMENT TOUTES LES AUTRES POLITIQUES
-- ===========================================================================

DO $$ 
DECLARE
    pol record;
BEGIN
    -- Supprimer toutes les politiques restantes sur UserDatas
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'UserDatas'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON "UserDatas"', pol.policyname);
        RAISE NOTICE 'Supprimé: % sur UserDatas', pol.policyname;
    END LOOP;
    
    -- Supprimer toutes les politiques restantes sur team_userdata
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'team_userdata'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON team_userdata', pol.policyname);
        RAISE NOTICE 'Supprimé: % sur team_userdata', pol.policyname;
    END LOOP;
END $$;

-- ===========================================================================
-- 3. CRÉER LES FONCTIONS RPC (avec OR REPLACE pour éviter les conflits)
-- ===========================================================================

-- Fonction pour incrémenter les tokens publics
CREATE OR REPLACE FUNCTION increment_user_tokens(
  user_id UUID,
  amount_to_add BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- Exécute avec les privilèges du propriétaire
AS $$
BEGIN
  UPDATE "UserDatas"
  SET tokens = tokens + amount_to_add
  WHERE id = user_id;
END;
$$;

-- Fonction pour incrémenter les tokens de groupe
CREATE OR REPLACE FUNCTION increment_team_tokens(
  p_team_id UUID,
  p_user_id UUID,
  amount_to_add BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- Exécute avec les privilèges du propriétaire
AS $$
BEGIN
  UPDATE team_userdata
  SET token = token + amount_to_add
  WHERE team_id = p_team_id AND userdata_id = p_user_id;
END;
$$;

-- ===========================================================================
-- 4. CRÉER LES NOUVELLES POLITIQUES PERMISSIVES
-- ===========================================================================

-- Politique permissive totale pour UserDatas
CREATE POLICY "allow_all_userdatas"
ON "UserDatas"
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Politique permissive totale pour team_userdata
CREATE POLICY "allow_all_team_userdata"
ON team_userdata
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- ===========================================================================
-- 5. S'ASSURER QUE RLS EST ACTIVÉ
-- ===========================================================================

ALTER TABLE "UserDatas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_userdata ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- 6. VÉRIFICATION - Afficher le résultat
-- ===========================================================================

-- Afficher les fonctions créées
SELECT 
    '✅ Fonctions RPC' as "Status",
    routine_name as "Fonction"
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE 'increment%'
ORDER BY routine_name;

-- Afficher les politiques créées
SELECT 
    '✅ Politiques RLS' as "Status",
    tablename as "Table",
    policyname as "Politique"
FROM pg_policies 
WHERE tablename IN ('UserDatas', 'team_userdata')
ORDER BY tablename, policyname;

-- Afficher le statut RLS
SELECT 
    '✅ RLS Status' as "Status",
    tablename as "Table", 
    CASE 
        WHEN rowsecurity THEN 'Activé'
        ELSE 'Désactivé'
    END as "RLS"
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('UserDatas', 'team_userdata')
ORDER BY tablename;

-- ===========================================================================
-- 7. CONFIRMATION
-- ===========================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║  ✅ POLITIQUES RLS NETTOYÉES ET RECRÉÉES AVEC SUCCÈS     ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Toutes les anciennes politiques ont été supprimées';
  RAISE NOTICE '✅ Nouvelles politiques permissives créées';
  RAISE NOTICE '✅ Fonctions RPC créées (increment_user_tokens, increment_team_tokens)';
  RAISE NOTICE '✅ RLS activé sur UserDatas et team_userdata';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Le système de distribution des gains est maintenant opérationnel !';
  RAISE NOTICE '';
END $$;

