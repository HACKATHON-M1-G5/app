-- ============================================================================
-- FIX DISTRIBUTION - Version Corrigée (gère les politiques existantes)
-- ============================================================================

-- ===========================================================================
-- 1. Créer ou remplacer les fonctions d'incrémentation de tokens
-- ===========================================================================

CREATE OR REPLACE FUNCTION increment_user_tokens(
  user_id UUID,
  amount_to_add BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE "UserDatas"
  SET tokens = tokens + amount_to_add
  WHERE id = user_id;
END;
$$;

CREATE OR REPLACE FUNCTION increment_team_tokens(
  p_team_id UUID,
  p_user_id UUID,
  amount_to_add BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE team_userdata
  SET token = token + amount_to_add
  WHERE team_id = p_team_id AND userdata_id = p_user_id;
END;
$$;

-- ===========================================================================
-- 2. Supprimer TOUTES les politiques RLS existantes
-- ===========================================================================

-- UserDatas
DROP POLICY IF EXISTS "allow_all_userdatas" ON "UserDatas";
DROP POLICY IF EXISTS "allow_token_distribution_public" ON "UserDatas";
DROP POLICY IF EXISTS "view_all_users" ON "UserDatas";
DROP POLICY IF EXISTS "update_own_profile" ON "UserDatas";
DROP POLICY IF EXISTS "allow_all_operations_userdatas" ON "UserDatas";
DROP POLICY IF EXISTS "select_own_data" ON "UserDatas";
DROP POLICY IF EXISTS "insert_own_data" ON "UserDatas";
DROP POLICY IF EXISTS "update_own_data" ON "UserDatas";
DROP POLICY IF EXISTS "Users can view all profiles" ON "UserDatas";
DROP POLICY IF EXISTS "Users can update own profile" ON "UserDatas";

-- team_userdata
DROP POLICY IF EXISTS "allow_all_team_userdata" ON team_userdata;
DROP POLICY IF EXISTS "allow_token_distribution_group" ON team_userdata;
DROP POLICY IF EXISTS "select_own_memberships" ON team_userdata;
DROP POLICY IF EXISTS "insert_membership" ON team_userdata;
DROP POLICY IF EXISTS "update_membership" ON team_userdata;
DROP POLICY IF EXISTS "allow_all_operations_team_userdata" ON team_userdata;
DROP POLICY IF EXISTS "select_team_memberships" ON team_userdata;
DROP POLICY IF EXISTS "insert_team_membership" ON team_userdata;
DROP POLICY IF EXISTS "update_team_membership" ON team_userdata;

-- ===========================================================================
-- 3. Créer UNE SEULE politique permissive pour chaque table
-- ===========================================================================

CREATE POLICY "allow_all_userdatas"
ON "UserDatas"
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "allow_all_team_userdata"
ON team_userdata
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- ===========================================================================
-- 4. S'assurer que RLS est activé
-- ===========================================================================

ALTER TABLE "UserDatas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_userdata ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- 5. CONFIRMATION
-- ===========================================================================

SELECT 
  '✅ Fonctions créées' as status,
  'increment_user_tokens et increment_team_tokens' as details
UNION ALL
SELECT 
  '✅ Politiques RLS créées',
  'allow_all_userdatas et allow_all_team_userdata'
UNION ALL
SELECT 
  '✅ RLS activé',
  'UserDatas et team_userdata'
UNION ALL
SELECT 
  '🎯 PRÊT',
  'La distribution des gains devrait maintenant fonctionner !';


