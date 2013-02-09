
local function Deal(self, numCards)

    local cards = { }
    for c = 1, #self.cards do
    
        local card = self.cards[c]
        if card.state == "in_deck" then
        
            card.state = "dealt"
            table.insert(cards, card.name)
            numCards = numCards - 1
            if numCards <= 0 then
                break
            end
            
        end
        
    end
    
    return cards
    
end

local function Create(cards)

    local deck = { }
    
    deck.cards = { }
    for c = 1, #cards do
        table.insert(deck.cards, { name = cards[c], state = "in_deck" })
    end
    
    deck.Deal = Deal
    
    return deck
    
end

return { Create = Create }