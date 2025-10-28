export interface UserData {
  id: string
  username: string
  winrate: number
  tokens: number
  created_at: string
  updated_at: string
  auth_id: string // Link to Supabase Auth user
}

export interface Team {
  id: string
  name: string
  description: string
  join_code: string
  primary_color: string
  icon_url: string
  privacy: boolean // true = private, false = public
  created_at: string
  updated_at: string
}

export interface TeamUserData {
  id: string
  joined_at: number
  status: 'pending' | 'member' | 'banned' | 'owner'
  userdata_id: string
  team_id: string
  token: number // tokens for this specific group
  created_at: string
  updated_at: string
}

export interface Prono {
  id: string
  team_id: string | null // null = public bet
  event_id: string | null // for future API integration
  owner_id: string
  name: string
  start_at: string
  end_at: string
  created_at: string
  updated_at: string
}

export interface Bet {
  id: string
  prono_id: string
  title: string
  odds: number
  result: boolean | null // null = pending, true = won, false = lost
  option_id: string | null // for future API integration
  created_at: string
  updated_at: string
}

export interface BetUserData {
  id: string
  amount: number
  created_at: number
  userdata_id: string
  bet_id: string
  updated_at: string
}

// Extended types with relations
export interface TeamWithMembers extends Team {
  members?: TeamUserData[]
  memberCount?: number
}

export interface PronoWithBets extends Prono {
  bets?: Bet[]
  owner?: UserData
  team?: Team
}

export interface BetWithDetails extends Bet {
  prono?: Prono
  userBets?: BetUserData[]
}

export interface UserBetWithDetails extends BetUserData {
  bet?: BetWithDetails
}
