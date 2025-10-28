# Guide de Distribution des Gains

## 📋 Vue d'ensemble

Le système de distribution des gains est maintenant **complètement fonctionnel** et automatisé.

## ✅ Modifications apportées

### 1. Page `/pronos/[id].vue`
- ✅ Utilise maintenant `setResultAndDistribute` au lieu de `updateBetResult`
- ✅ Distribue automatiquement les gains aux gagnants
- ✅ Affiche une confirmation avec avertissement avant de valider
- ✅ Recharge les statistiques après la distribution

### 2. Composable `useResults.ts`
Le composable contient les fonctions suivantes :
- `setResultAndDistribute(betId, result)` : Définit le résultat ET distribue les gains si gagnant
- `distributeWinnings(betId)` : Distribue les gains aux gagnants d'un bet
- `pronoHasResults(pronoId)` : Vérifie si un prono a des résultats
- `pronoAllResultsDefined(pronoId)` : Vérifie si tous les résultats sont définis

### 3. Migrations SQL
Les migrations suivantes doivent être exécutées dans l'ordre :
1. `20251028_SOLUTION_COMPLETE.sql` - Crée les fonctions RPC et configure les RLS
2. `SOLUTION_FINALE_RLS.sql` - Solution de secours si les RLS bloquent

## 🎯 Comment ça fonctionne ?

### Flux de distribution des gains

1. **L'admin définit un résultat** (sur une des pages suivantes) :
   - `/pronos/[id]` - Page publique du prono
   - `/admin/results/[id]` - Page admin dédiée
   - `/groups/[teamId]/results/[pronoId]` - Page de résultats du groupe

2. **Le système vérifie automatiquement** :
   - Si le résultat est "gagné" (true) → Distribution des gains
   - Si le résultat est "perdu" (false) → Pas de distribution

3. **Distribution des gains** :
   - Pour chaque pari sur l'option gagnante :
     - Calcul du gain : `montant × cote`
     - Si c'est un pari de groupe → Crédite les tokens du groupe (`team_userdata.token`)
     - Si c'est un pari public → Crédite les tokens globaux (`UserDatas.tokens`)

4. **Confirmation** :
   - Les paris sont marqués comme "terminés" (via `result !== null`)
   - Les utilisateurs ne peuvent plus parier une fois les résultats définis
   - Un badge "🔒 Résultats définis" s'affiche

## 🔧 Fonctions RPC PostgreSQL

### `increment_user_tokens(user_id, amount_to_add)`
Incrémente les tokens globaux d'un utilisateur avec `SECURITY DEFINER` pour bypasser les RLS.

```sql
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
```

### `increment_team_tokens(p_team_id, p_user_id, amount_to_add)`
Incrémente les tokens de groupe d'un utilisateur avec `SECURITY DEFINER` pour bypasser les RLS.

```sql
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
```

## 🚀 Déploiement

### 1. Exécuter les migrations Supabase

```bash
# Appliquer les migrations
supabase db push

# OU manuellement via le Dashboard Supabase :
# 1. Aller dans SQL Editor
# 2. Copier le contenu de 20251028_SOLUTION_COMPLETE.sql
# 3. Exécuter la requête
```

### 2. Vérifier que les fonctions existent

```sql
-- Lister les fonctions
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE 'increment%';
```

### 3. Tester la distribution

```sql
-- Test manuel (remplacer les IDs)
SELECT increment_user_tokens('USER_ID_HERE'::UUID, 100);
SELECT tokens FROM "UserDatas" WHERE id = 'USER_ID_HERE'::UUID;
```

## 🐛 Dépannage

### Si les gains ne sont pas distribués :

1. **Vérifier les logs dans la console du navigateur** :
   - Ouvrir les DevTools (F12)
   - Chercher les messages de `useResults.ts`
   - Les logs préfixés par 🎯, 💰, ✅ ou ❌

2. **Vérifier que les fonctions RPC existent** :
   ```sql
   \df increment*
   ```

3. **Vérifier les politiques RLS** :
   ```sql
   SELECT tablename, policyname, permissive, roles, cmd
   FROM pg_policies 
   WHERE tablename IN ('UserDatas', 'team_userdata');
   ```

4. **Solution de secours** : Exécuter `SOLUTION_FINALE_RLS.sql` qui crée des politiques ultra-permissives

### Si les RLS bloquent encore :

```sql
-- Option nucléaire (pour développement uniquement)
ALTER TABLE "UserDatas" DISABLE ROW LEVEL SECURITY;
ALTER TABLE team_userdata DISABLE ROW LEVEL SECURITY;
```

## 📝 Interfaces utilisateur

### Badge "Terminé"
Quand un prono a des résultats :
- Badge rouge "Terminé" sur la liste des pronos
- Badge "🔒 Résultats définis" sur la page du prono
- Message "Les paris sont fermés et les gains ont été distribués"

### Empêcher les paris après résultats
La condition `!hasResults` dans le template empêche de parier :
```vue
:can-bet="(isActive || isPending) && !hasResults && ..."
```

### Confirmation admin
Message de confirmation avant validation :
```
Êtes-vous sûr de marquer cette option comme gagnante/perdante ?
Les tokens seront distribués automatiquement aux gagnants.
```

## 🎉 Résumé

✅ Les gains sont distribués automatiquement quand l'admin choisit un gagnant
✅ Les paris passent en "terminé" dès qu'un résultat est défini
✅ Les utilisateurs ne peuvent plus parier après définition des résultats
✅ Fonctionne pour les paris publics ET les paris de groupe
✅ Gestion robuste avec méthode de secours si les RPC échouent

Le système est **prêt à l'emploi** ! 🚀

