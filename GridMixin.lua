
GridMixin = { type = "Grid" }

function GridMixin:__initmixin()

    self.gridPos = vec2(0, 0)
    self.gridLayer = 1
    self.usesGridPositionForRendering = true
    self.gridViewer = false
    
end

function GridMixin:SetGridPosition(setPos)
    self.gridPos = setPos
end

function GridMixin:GetGridPosition()
    return self.gridPos
end

function GridMixin:SetGridLayer(setLayer)
    self.gridLayer = setLayer
end

function GridMixin:GetGridLayer()
    return self.gridLayer
end

function GridMixin:SetUsesGridPositionForRendering(usesForRendering)
    self.usesGridPositionForRendering = usesForRendering
end

function GridMixin:GetUsesGridPositionForRendering()
    return self.usesGridPositionForRendering
end

function GridMixin:SetGridViewer(setViewer)
    self.gridViewer = setViewer
end

function GridMixin:GetGridViewer()
    return self.gridViewer
end