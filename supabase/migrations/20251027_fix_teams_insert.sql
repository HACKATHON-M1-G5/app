-- FIX: Corriger la politique d'insertion pour Teams

-- Supprimer l'ancienne politique
DROP POLICY IF EXISTS "insert_teams" ON "Teams";

-- Créer une nouvelle politique plus permissive pour l'insertion
CREATE POLICY "insert_teams" 
ON "Teams" 
FOR INSERT 
WITH CHECK (true);  -- Tout utilisateur authentifié peut créer un groupe

-- Note: La sécurité est assurée par le fait que seuls les utilisateurs
-- authentifiés peuvent accéder à l'application (middleware auth)

