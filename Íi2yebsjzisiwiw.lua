local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser") -- Dùng để auto click chuột

local LocalPlayer = Players.LocalPlayer

-- ================= CẤU HÌNH AUTO FARM =================
_G.AutoFarm = true         -- Bật/Tắt Auto Farm (true là bật, false là tắt)
local MONSTER_NAME = "Thug" -- ĐỔI THÀNH TÊN QUÁI VẬT BẠN MUỐN FARM
local TWEEN_SPEED = 40      -- Tốc độ bay (Không nên để quá cao để tránh bị kick/ban)
local FARM_HEIGHT = 5       -- Khoảng cách đứng trên đầu quái để né chiêu
-- =======================================================

-- 1. HÀM TÌM QUÁI VẬT GẦN NHẤT THEO TÊN
local function getClosestMonster()
    local closest = nil
    local shortestDistance = math.huge
    
    -- Quét toàn bộ Workspace (hoặc đổi thành Folder chứa quái của game bạn)
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == MONSTER_NAME then
            local humanoid = child:FindFirstChildOfClass("Humanoid")
            local rootPart = child:FindFirstChild("HumanoidRootPart")
            
            if humanoid and rootPart and humanoid.Health > 0 then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = child
                    end
                end
            end
        end
    end
    return closest
end

-- 2. HÀM DI CHUYỂN MƯỢT MÀ (TWEEN)
local function tweenTo(targetCFrame)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    local duration = distance / TWEEN_SPEED

    -- Tạo hiệu ứng bay mượt mà không bị giật
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait() -- Đợi bay tới nơi mới làm việc tiếp
end

-- 3. HÀM TỰ ĐỘNG TRANG BỊ VŨ KHÍ VÀ CLICK ĐÁNH
local function autoAttack()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if not character then return end

    -- Tự động lấy vũ khí đầu tiên trong balo nếu tay đang trống
    if not character:FindFirstChildOfClass("Tool") then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then
            tool.Parent = character
        end
    end

    -- Kích hoạt click chuột ảo để tấn công
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(0,0))
end

-- 4. VÒNG LẶP CHÍNH (MAIN LOOP)
task.spawn(function()
    while _G.AutoFarm do
        task.wait(0.1) -- Giảm tải cho game
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
        
        local monster = getClosestMonster()
        if monster and monster:FindFirstChild("HumanoidRootPart") then
            -- Tính toán vị trí an toàn ngay trên đầu quái vật
            local targetPos = monster.HumanoidRootPart.CFrame * CFrame.new(0, FARM_HEIGHT, 0)
            
            -- Nếu ở quá xa thì di chuyển tới, nếu đã ở gần thì khóa vị trí và đánh
            if (character.HumanoidRootPart.Position - targetPos.Position).Magnitude > 10 then
                tweenTo(targetPos)
            else
                character.HumanoidRootPart.CFrame = targetPos
                autoAttack()
            end
        end
    end
end)

