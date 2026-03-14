local HowManyLeft = {
    installed = false,
}

-- Named {C:} colour tags from Balatro's LOC_COLOURS
local SUIT_COLOR_TAGS = {
    Hearts   = "{C:hearts}",
    Diamonds = "{C:diamonds}",
    Clubs    = "{C:clubs}",
    Spades   = "{C:spades}",
}

local function get_rank_label(card)
    if not card or not card.base then return "?" end
    local value = card.base.value
    if not value then return "?" end
    -- Use the display value directly — card_key maps 10→"T" which is unreadable
    -- G.localization.misc.ranks contains the display string per rank
    if G and G.localization and G.localization.misc
        and G.localization.misc.ranks and G.localization.misc.ranks[value] then
        return G.localization.misc.ranks[value]
    end
    return tostring(value)
end

local function get_suit_key(card)
    if not card or not card.base then return nil end
    local s = card.base.suit
    if not s then return nil end
    if SUIT_COLOR_TAGS[s] then return s end
    if SMODS and SMODS.Suits then
        for k, v in pairs(SMODS.Suits) do
            if k == s or (v.name and v.name == s) then
                if k == "S" then return "Spades" end
                if k == "H" then return "Hearts" end
                if k == "C" then return "Clubs" end
                if k == "D" then return "Diamonds" end
                return k
            end
        end
    end
    return s
end

-- Get the localized suit name (plural) from Balatro's own localization table
local function get_suit_label(suit_key)
    if G and G.localization and G.localization.misc
        and G.localization.misc.suits_plural
        and G.localization.misc.suits_plural[suit_key] then
        return G.localization.misc.suits_plural[suit_key]
    end
    local fallback = {
        Hearts = "Hearts", Diamonds = "Diamonds",
        Clubs = "Clubs", Spades = "Spades"
    }
    return fallback[suit_key] or suit_key or "?"
end

local function get_deck_counts(card)
    if not card or not card.base then return 0, 0 end
    local target_rank = card.base.value
    local target_suit = card.base.suit
    if not target_rank or not target_suit then return 0, 0 end
    if not (G and G.deck and type(G.deck.cards) == 'table') then return 0, 0 end

    local rank_left, suit_left = 0, 0
    for _, c in ipairs(G.deck.cards) do
        if c ~= card and c.base then
            if c.base.value == target_rank then rank_left = rank_left + 1 end
            if c.base.suit == target_suit then suit_left = suit_left + 1 end
        end
    end
    return rank_left, suit_left
end

local function get_header_label()
    if G and G.localization
        and G.localization.descriptions
        and G.localization.descriptions.Other
        and G.localization.descriptions.Other.hml_info
        and G.localization.descriptions.Other.hml_info.name then
        return G.localization.descriptions.Other.hml_info.name
    end
    return "In the deck"
end

local function build_loc_entry(name_str, line1, line2)
    local entry = {
        name = name_str,
        text = { line1, line2 },
        name_parsed = {},
        text_parsed = {},
    }
    if loc_parse_string then
        entry.name_parsed[1] = loc_parse_string(name_str)
        entry.text_parsed[1] = loc_parse_string(line1)
        entry.text_parsed[2] = loc_parse_string(line2)
    end
    return entry
end

local function append_tooltip(info_queue, card)
    if not info_queue or not card or not card.base then return end

    local rank_left, suit_left = get_deck_counts(card)
    local rank_label  = get_rank_label(card)
    local suit_key    = get_suit_key(card) or card.base.suit or "?"
    local suit_label  = get_suit_label(suit_key)  -- localized name, e.g. "Cuori"
    local suit_ctag   = SUIT_COLOR_TAGS[suit_key] or "{C:inactive}"
    local header      = get_header_label()

    local line1 = "{C:blue}" .. rank_label .. "{C:black} : " .. tostring(rank_left)
    local line2 = suit_ctag .. suit_label .. "{C:black} : " .. tostring(suit_left)

    if G and G.localization and G.localization.descriptions then
        if not G.localization.descriptions.Other then
            G.localization.descriptions.Other = {}
        end
        G.localization.descriptions.Other.hml_dynamic = build_loc_entry(header, line1, line2)
    end

    info_queue[#info_queue + 1] = {
        set = 'Other',
        key = 'hml_dynamic',
    }
end

local function wrap_suit_loc_vars(suit_obj)
    if not suit_obj or suit_obj.hml_wrapped then return end
    suit_obj.hml_wrapped = true

    local original_loc_vars = suit_obj.loc_vars
    suit_obj.loc_vars = function(self, info_queue, card)
        if original_loc_vars then
            original_loc_vars(self, info_queue, card)
        end
        append_tooltip(info_queue, card)
    end
end

local function install_hooks()
    if HowManyLeft.installed then return end
    if not SMODS or not SMODS.Suit or not SMODS.Suit.obj_buffer or not SMODS.Suits then return end
    for _, suit_key in ipairs(SMODS.Suit.obj_buffer) do
        wrap_suit_loc_vars(SMODS.Suits[suit_key])
    end
    HowManyLeft.installed = true
end

install_hooks()

local game_init_game_object_ref = Game.init_game_object
function Game:init_game_object()
    local out = game_init_game_object_ref(self)
    install_hooks()
    return out
end

return HowManyLeft
