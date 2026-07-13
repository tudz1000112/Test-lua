local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Cấu hình màu sắc
local ESP_COLOR = Color3.fromRGB(255, 0, 0) -- Màu đỏ cho viền định vị
local HEALTH_GOOD = Color3.fromRGB(0, 255, 0) -- Máu đầy (Xanh lá)
local HEALTH_LOW = Color3.fromRGB(255, 0, 0) -- Máu thấp (Đỏ)

-- Hàm tạo định vị và thanh máu cho quái vật
local function createMonsterESP(monster)
    -- Kiểm tra xem đối tượng có phải là quái vật (có Humanoid và HumanoidRootPart) không
    local humanoid = monster:FindFirstChildOfClass("Humanoid")
    local rootPart = monster:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart or monster == LocalPlayer.Character then return end
    if rootPart:FindFirstChild("HealthBarGUI") then return end -- Tránh tạo trùng

    -- 1. TẠO VIỀN ĐỊNH VỊ (HIGHLIGHT ESP)
    local highlight = Instance.new("Highlight")
    highlight.Name = "MonsterESP"
    highlight.FillColor = ESP_COLOR
    highlight.FillTransparency = 0.6 -- Độ trong suốt của thân quái
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Viền trắng xuyên tường
    highlight.OutlineTransparency = 0
    highlight.Adornee = monster
    highlight.Parent = monster

    -- 2. TẠO THANH MÁU TRÊN ĐẦU (BILLBOARD GUI)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HealthBarGUI"
    billboard.Size = UDim2.new(3.5, 0, 0.8, 0)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0) -- Chiều cao hiển thị trên đầu quái
    billboard.AlwaysOnTop = true -- Luôn hiện trên cùng, xuyên tường
    billboard.Adornee = rootPart
    billboard.Parent = rootPart

    -- Khung nền (Background) của thanh máu
    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(1, 0, 0.3, 0)
    bgFrame.Position = UDim2.new(0, 0, 0.7, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bgFrame.BorderSizePixel = 1
    bgFrame.Parent = billboard

    -- Thanh máu thực tế (Fill)
    local healthFrame = Instance.new("Frame")
    healthFrame.Size = UDim2.new(1, 0, 1, 0)
    healthFrame.BackgroundColor3 = HEALTH_GOOD
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = bgFrame

    -- Tên của quái vật
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = monster.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboard

    -- Hàm cập nhật thanh máu khi quái bị đánh
    local function updateHealth()
        if humanoid and humanoid.Parent then
            local healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            -- Hiệu ứng co giãn thanh máu
            healthFrame:TweenSize(UDim2.new(healthRatio, 0, 1, 0), "Out", "Quad", 0.2, true)
            
            -- Đổi màu thanh máu dựa trên lượng máu còn lại
            if healthRatio < 0.3 then
                healthFrame.BackgroundColor3 = HEALTH_LOW
            elseif healthRatio < 0.7 then
                healthFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Vàng
            else
                healthFrame.BackgroundColor3 = HEALTH_GOOD
            end
        end
    end

    -- Lắng nghe sự kiện thay đổi máu
    local healthConn
    healthConn = humanoid.HealthChanged:Connect(function()
        if not monster.Parent or humanoid.Health <= 0 then
            billboard:Destroy()
            highlight:Destroy()
            healthConn:Disconnect()
        else
            updateHealth()
        end
    end)

    updateHealth() -- Chạy cập nhật lần đầu tiên
end

-- QUẢN LÝ QUÉT QUÁI VẬT TRONG CÁC KHU VỰC
-- Thay "Workspace" thành Folder chứa quái của bạn nếu có (Ví dụ: Workspace.Enemies)
local monsterContainer = Workspace 

-- Quét các quái vật đã có sẵn khi vừa vào game
for _, child in ipairs(monsterContainer:GetChildren()) do
    if child:IsA("Model") then
        createMonsterESP(child)
    end
end

-- Tự động quét và áp dụng khi quái vật mới xuất hiện (Respawn)
monsterContainer.ChildAdded:Connect(function(child)
    task.wait(0.1) -- Đợi một chút để quái vật tải đủ bộ phận
    if child:IsA("Model") then
        createMonsterESP(child)
    end
end)

