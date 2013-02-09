
UpgradableMixin = { type = "Upgradable" }

function UpgradableMixin:__initmixin()
    self.upgrades = { }
end

function UpgradableMixin:AddUpgrade(upgradeName)

    local upgrade = self.upgrades[upgradeName]
    self.upgrades[upgradeName] = upgrade and upgrade + 1 or 1
    
end

function UpgradableMixin:GetUpgrade(upgradeName)
    return self.upgrades[upgradeName] and self.upgrades[upgradeName] or 0
end

function UpgradableMixin:GetHasUpgrade(upgradeName)

    local upgrade = self.upgrades[upgradeName]
    return upgrade ~= nil and upgrade > 0
    
end