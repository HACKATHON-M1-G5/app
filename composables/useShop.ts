export const useShop = () => {
    const supabase = useSupabaseClient()
    const { whenUserDataReady } = useUserData()

    const ensureUser = async () => {
        const ud = await whenUserDataReady()
        if (!ud) throw new Error('User not authenticated')
        return ud
    }

    const getItems = async () => {
        return [
            {
                "id": "0a1b2c3d-0001-4f2a-9cde-111111111111",
                "name": "Badge VIP",
                "description": "Badge profil exclusif affiché à côté de votre pseudo.",
                "price": 150,
                "category": "privileges",
                "image": "https://picsum.photos/seed/plant/640/360",
                "limited": false,
                "created_at": "2025-09-10T10:12:00Z"
            },
            {
                "id": "0a1b2c3d-0002-4f2a-9cde-222222222222",
                "name": "Pack Stickers",
                "description": "10 stickers cosmétiques pour personnaliser votre profil.",
                "price": 50,
                "category": "cosmetics",
                "image": "https://picsum.photos/seed/stickers/640/360",
                "limited": false,
                "created_at": "2025-08-21T09:00:00Z"
            },
            {
                "id": "0a1b2c3d-0003-4f2a-9cde-333333333333",
                "name": "Boost XP (24h)",
                "description": "Augmente vos gains d'XP de 50% pendant 24 heures.",
                "price": 120,
                "category": "boosts",
                "image": "https://picsum.photos/seed/boostxp/640/360",
                "limited": false,
                "created_at": "2025-10-01T14:30:00Z"
            },
            {
                "id": "0a1b2c3d-0004-4f2a-9cde-444444444444",
                "name": "Couleur de pseudo",
                "description": "Change la couleur de ton pseudo dans les chats.",
                "price": 80,
                "category": "cosmetics",
                "image": "https://picsum.photos/seed/color/640/360",
                "limited": false,
                "created_at": "2025-07-15T12:00:00Z"
            },
            {
                "id": "0a1b2c3d-0005-4f2a-9cde-555555555555",
                "name": "Accès salon privé",
                "description": "Donne l'accès au salon Discord réservé aux membres premium.",
                "price": 300,
                "category": "privileges",
                "image": "https://picsum.photos/seed/lounge/640/360",
                "limited": true,
                "created_at": "2025-09-30T08:45:00Z"
            },
            {
                "id": "0a1b2c3d-0006-4f2a-9cde-666666666666",
                "name": "Badge Saison (édition)",
                "description": "Badge limité de la saison en cours (édition collector).",
                "price": 500,
                "category": "cosmetics",
                "image": "https://picsum.photos/seed/season/640/360",
                "limited": true,
                "created_at": "2025-10-05T18:20:00Z"
            },
            {
                "id": "0a1b2c3d-0007-4f2a-9cde-777777777777",
                "name": "Boost Récompense",
                "description": "Double la récompense tokens d'une prochaine tâche accomplie.",
                "price": 200,
                "category": "boosts",
                "image": "https://picsum.photos/seed/rewardboost/640/360",
                "limited": false,
                "created_at": "2025-06-02T11:11:00Z"
            },
            {
                "id": "0a1b2c3d-0008-4f2a-9cde-888888888888",
                "name": "Avatar animé",
                "description": "Avatar animé pour ton profil (GIF loop).",
                "price": 400,
                "category": "cosmetics",
                "image": "https://picsum.photos/seed/avatar/640/360",
                "limited": false,
                "created_at": "2025-09-01T07:30:00Z"
            },
            {
                "id": "0a1b2c3d-0009-4f2a-9cde-999999999999",
                "name": "Téléport marqueur",
                "description": "Place un marqueur spécial sur la map (visible par toi seulement).",
                "price": 90,
                "category": "privileges",
                "image": "https://picsum.photos/seed/teleport/640/360",
                "limited": false,
                "created_at": "2025-05-20T16:00:00Z"
            },
            {
                "id": "0a1b2c3d-000a-4f2a-9cde-aaaaaaaaaaaa",
                "name": "Pack Décor (3)",
                "description": "Trois éléments décoratifs pour ton profil ou espace personnel.",
                "price": 180,
                "category": "cosmetics",
                "image": "https://picsum.photos/seed/decor/640/360",
                "limited": false,
                "created_at": "2025-08-05T13:00:00Z"
            },
            {
                "id": "0a1b2c3d-000b-4f2a-9cde-bbbbbbbbbbbb",
                "name": "X2 Gains (1h)",
                "description": "Double les gains de tokens pendant 1 heure.",
                "price": 220,
                "category": "boosts",
                "image": "https://picsum.photos/seed/x2/640/360",
                "limited": false,
                "created_at": "2025-10-12T09:10:00Z"
            },
        ]
    }

    const purchaseItem = async (itemId: string) => {
        const userData = await ensureUser()
    }

    return {
        getItems,
        purchaseItem,
    }
}

export interface ShopItem {
    id: string
    name: string
    description?: string
    price: number
    category: 'cosmetics' | 'boosts' | 'privileges'
    image?: string
    limited?: boolean
    created_at?: string | number
}