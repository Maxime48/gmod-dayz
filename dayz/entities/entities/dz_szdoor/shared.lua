ENT.Type 			= "anim"
ENT.PrintName		= ""
ENT.Author			= "Phoenixf129"
ENT.Contact			= ""
ENT.Purpose			= "Teleports user out of the safezone"
ENT.Instructions	= ""
------------------------------------

local portal_color = Vector((30 * 2) / 255, (0 * 2) / 255, (30 * 2) / 255)

local function InFront(posA, posB, normal)
	local Vec1 = (posB - posA):GetNormalized();

	return (normal:Dot(Vec1) >= 0);
end;


function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS;
end;

local color = Color(200,200,200,255)

local clamp = math.Clamp;
local abs = math.abs;
local min, max = math.min, math.max;

function HSLToColor(H, S, L)
	H = clamp(H, 0, 360);
	S = clamp(S, 0, 1);
	L = clamp(L, 0, 1);
	local C = (1 - abs(2 * L - 1)) * S;
	local X = C * (1 - abs((H / 60) % 2 - 1));
	local m = L - C / 2;
	local R1, G1, B1 = 0, 0, 0;

	if H < 60 or H >= 360 then
		R1, G1, B1 = C, X, 0;
	elseif H < 120 then
		R1, G1, B1 = X, C, 0;
	elseif H < 180 then
		R1, G1, B1 = 0, C, X;
	elseif H < 240 then
		R1, G1, B1 = 0, X, C;
	elseif H < 300 then
		R1, G1, B1 = X, 0, C;
	else
		R1, G1, B1 = C, 0, X; -- H < 360
	end

	return Color((R1 + m) * 255, (G1 + m) * 255, (B1 + m) * 255);
end

function ColorToHSL(R, G, B)
	if type(R) == "table" then
		R, G, B = clamp(R.r, 0, 255) / 255, clamp(R.g, 0, 255) / 255, clamp(R.b, 0, 255) / 255;
	else
		R, G, B = R / 255, G / 255, B / 255;
	end

	local max, min = max(R, G, B), min(R, G, B);
	local del = max - min;
	-- Hue
	local H = 0;

	if del <= 0 then
		H = 0;
	elseif max == R then
		H = 60 * (((G - B) / del) % 6);
	elseif max == G then
		H = 60 * (((B - R) / del + 2) % 6);
	else
		H = 60 * (((R - G) / del + 4) % 6);
	end

	-- Lightness
	local L = (max + min) / 2;
	-- Saturation
	local S = 0;

	if del != 0 then
		S = del / (1 - abs(2 * L - 1));
	end

	return H, S, L;
end

if CLIENT then
	local function DefineClipBuffer(ref)
		render.ClearStencil();
		render.SetStencilEnable(true);
		render.SetStencilCompareFunction(STENCIL_ALWAYS);
		render.SetStencilPassOperation(STENCIL_REPLACE);
		render.SetStencilFailOperation(STENCIL_KEEP);
		render.SetStencilZFailOperation(STENCIL_KEEP);
		render.SetStencilWriteMask(254);
		render.SetStencilTestMask(254);
		render.SetStencilReferenceValue(ref or 43);
	end;

	local function DrawToBuffer()
		render.SetStencilCompareFunction(STENCIL_EQUAL);
	end;

	local function EndClipBuffer()
		render.SetStencilEnable(false);
		render.ClearStencil();
	end;
	local offset = 1.8

	function ENT:GetEnabled()
		return true
	end

	function ENT:Initialize()
		self.PixVis = util.GetPixelVisibleHandle();
		local matrix = Matrix();
		matrix:Scale(Vector(1, 1, 0.01));
		local offset = 1.8;

		self:SetSolid(SOLID_VPHYSICS);

		self.hole = ClientsideModel("models/hunter/plates/plate1x2.mdl", RENDERGROUP_BOTH);
		self.hole:SetPos(self:GetPos() - self:GetUp() * (1 + offset));
		self.hole:SetAngles(self:GetAngles());
		self.hole:SetParent(self);
		self.hole:SetNoDraw(true);	
		self.hole:EnableMatrix("RenderMultiply", matrix);

		self.top = ClientsideModel("models/hunter/plates/plate075x1.mdl", RENDERGROUP_BOTH);
		self.top:SetMaterial("portal/border");
		self.top:SetPos(self:GetPos() + self:GetRight() * 44.5 - self:GetUp() * (12.5 + offset));
		self.top:SetParent(self);
		self.top:SetLocalAngles(Angle(-75, -90, 0));
		self.top:SetNoDraw(true);
		self.top:EnableMatrix("RenderMultiply", matrix);

		self.bottom = ClientsideModel("models/hunter/plates/plate075x1.mdl", RENDERGROUP_BOTH);
		self.bottom:SetMaterial("portal/border");
		self.bottom:SetPos(self:GetPos() - self:GetRight() * 44.5 - self:GetUp() * (12.5 + offset));
		self.bottom:SetParent(self);
		self.bottom:SetLocalAngles(Angle(-75, 90, 0));
		self.bottom:SetNoDraw(true);
		self.bottom:EnableMatrix("RenderMultiply", matrix);

		self.left = ClientsideModel("models/hunter/plates/plate075x2.mdl", RENDERGROUP_BOTH);
		self.left:SetMaterial("portal/border");
		self.left:SetPos(self:GetPos() + self:GetForward() * 20.8 - self:GetUp() * (12.5 + offset));
		self.left:SetParent(self);
		self.left:SetLocalAngles(Angle(-75, 0, 0));
		self.left:SetNoDraw(true);
		self.left:EnableMatrix("RenderMultiply", matrix);

		self.right = ClientsideModel("models/hunter/plates/plate075x2.mdl", RENDERGROUP_BOTH);
		self.right:SetMaterial("portal/border");
		self.right:SetPos(self:GetPos() - self:GetForward() * 20.8 - self:GetUp() * (12.5 + offset));
		self.right:SetParent(self);
		self.right:SetLocalAngles(Angle(-105, 0, 0));
		self.right:SetNoDraw(true);
		self.right:EnableMatrix("RenderMultiply", matrix);

		self.back = ClientsideModel("models/hunter/plates/plate3x3.mdl", RENDERGROUP_BOTH);	
		self.back:SetMaterial("vgui/black");
		self.back:SetPos(self:GetPos() - self:GetUp() * 42);
		self.back:SetParent(self);
		self.back:SetLocalAngles(angle_zero);
		self.back:SetNoDraw(true);

		self.h, self.s, self.l = 0, 1, 1;
	end;

	function ENT:OnRemove()
		self.top:Remove();
		self.bottom:Remove();
		self.left:Remove();
		self.right:Remove();
		self.hole:Remove();
		self.back:Remove();
	end;

	function ENT:Draw()

	end;

	local matrix = Matrix();
	matrix:Scale(Vector(1, 1, 0.01));

	function ENT:Think()
		--if (self:GetEnabled()) then
			local light = DynamicLight(self:EntIndex());

			if (light) then
				local vecCol = portal_color
				light.pos = self:WorldSpaceCenter() + self:GetUp() * 15;
				light.Size = 300;
				light.style = 5;
				light.Decay = 600;
				light.brightness = 1;
				light.r = (vecCol.x / 2) * 255;
				light.g = (vecCol.y / 2) * 255;
				light.b = (vecCol.z / 2) * 255;
				light.DieTime = CurTime() + 0.1;
			end;
		--end;

		if (!IsValid(self.hole)) then
			self.hole = ClientsideModel("models/hunter/plates/plate1x2.mdl", RENDERGROUP_BOTH);
			self.hole:SetPos(self:GetPos() - self:GetUp() * (1 + offset));
			self.hole:SetAngles(self:GetAngles());
			self.hole:SetParent(self);
			self.hole:SetNoDraw(true);
			self.hole:EnableMatrix("RenderMultiply", matrix);
		end;

		if (!IsValid(self.top)) then
			self.top = ClientsideModel("models/hunter/plates/plate075x1.mdl", RENDERGROUP_BOTH);
			self.top:SetMaterial("portal/border");
			self.top:SetPos(self:GetPos() + self:GetRight() * 44.5 - self:GetUp() * (12.5 + offset));
			self.top:SetParent(self);
			self.top:SetLocalAngles(Angle(-75, -90, 0));
			self.top:SetNoDraw(true);
			self.top:EnableMatrix("RenderMultiply", matrix);
		end;

		if (!IsValid(self.bottom)) then
			self.bottom = ClientsideModel("models/hunter/plates/plate075x1.mdl", RENDERGROUP_BOTH);
			self.bottom:SetMaterial("portal/border");
			self.bottom:SetPos(self:GetPos() - self:GetRight() * 44.5 - self:GetUp() * (12.5 + offset));
			self.bottom:SetParent(self);
			self.bottom:SetLocalAngles(Angle(-75, 90, 0));
			self.bottom:SetNoDraw(true);
			self.bottom:EnableMatrix("RenderMultiply", matrix);
		end;

		if (!IsValid(self.left)) then
			self.left = ClientsideModel("models/hunter/plates/plate075x2.mdl", RENDERGROUP_BOTH);
			self.left:SetMaterial("portal/border");
			self.left:SetPos(self:GetPos() + self:GetForward() * 20.8 - self:GetUp() * (12.5 + offset));
			self.left:SetParent(self);
			self.left:SetLocalAngles(Angle(-75, 0, 0));
			self.left:SetNoDraw(true);
			self.left:EnableMatrix("RenderMultiply", matrix);
		end;

		if (!IsValid(self.right)) then
			self.right = ClientsideModel("models/hunter/plates/plate075x2.mdl", RENDERGROUP_BOTH);
			self.right:SetMaterial("portal/border");
			self.right:SetPos(self:GetPos() - self:GetForward() * 20.8 - self:GetUp() * (12.5 + offset));
			self.right:SetParent(self);
			self.right:SetLocalAngles(Angle(-105, 0, 0));
			self.right:SetNoDraw(true);
			self.right:EnableMatrix("RenderMultiply", matrix);
		end;

		if (!IsValid(self.back)) then
			self.back = ClientsideModel("models/hunter/plates/plate3x3.mdl", RENDERGROUP_BOTH);
			self.back:SetMaterial("vgui/black");
			self.back:SetPos(self:GetPos() - self:GetUp() * 42);
			self.back:SetParent(self);
			self.back:SetLocalAngles(angle_zero);
			self.back:SetNoDraw(true);
		end;

		self.top:SetParent(self);
		self.bottom:SetParent(self);
		self.left:SetParent(self);
		self.right:SetParent(self);
		self.hole:SetParent(self);
		self.back:SetParent(self);
	end;

	local mat = CreateMaterial("windowGlow", "UnlitGeneric", {
		["$basetexture"] = "sprites/light_glow02",
		["$basetexturetransform"] = "center 0 0 scale 1 1 rotate 0 translate 0 0",
		["$additive"] = 1,
		["$translucent"] = 1,
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$ignorez"] = 1
	});

	local animstart = CurTime()
	function ENT:DrawTranslucent()
		if (InFront(LocalPlayer():EyePos(), self:GetPos() - self:GetUp() * 1.8, self:GetUp())) then return; end;

		local bEnabled = true;
		local color = portal_color;
		local elapsed = CurTime() - animstart;
		local frac = math.Clamp(elapsed / (bEnabled and 0.5 or 0.1), 0, 1);

		if (frac <= 1) then
			self.h, self.s, self.l = ColorToHSL((portal_color.x / 2) * 255, (portal_color.y / 2) * 255, (portal_color.z / 2) * 255);
			self.l = Lerp(frac, self.l or 1, bEnabled and 0 or 1);
			self.col = HSLToColor(self.h, self.s, self.l);
		end;

		if (bEnabled) then
			self.lerpr = Lerp(frac, self.lerpr or 255, self.col.r);
			self.lerpg = Lerp(frac, self.lerpg or 255, self.col.g);
			self.lerpb = Lerp(frac, self.lerpb or 255, self.col.b);
		else
			self.lerpr = Lerp(frac, self.lerpr or 0, self.col.r);
			self.lerpg = Lerp(frac, self.lerpg or 0, self.col.g);
			self.lerpb = Lerp(frac, self.lerpb or 0, self.col.b);
		end;

		self.top:SetNoDraw(true);

		DefineClipBuffer();

		if ((bEnabled and frac > 0) or (!bEnabled and frac < 1)) then
			self.hole:DrawModel();
		end;

		DrawToBuffer();

		render.ClearBuffersObeyStencil(self.lerpr, self.lerpg, self.lerpb, 0, bEnabled);

		if (bEnabled and frac >= 0.1) then
			if (frac >= 1) then
				self.back:DrawModel();
			end;
			render.SetColorModulation(color.x * 3, color.y * 3, color.z * 3);
			self.top:DrawModel();
			self.bottom:DrawModel();
			self.left:DrawModel();
			self.right:DrawModel();
			render.SetColorModulation(1, 1, 1);
		end;

		EndClipBuffer();

		if (!bEnabled) then return; end;

		local norm = self:GetUp();
		local viewNorm = (self:GetPos() - EyePos()):GetNormalized();
		local dot = viewNorm:Dot(norm * -1);

		if (dot >= 0) then
			render.SetColorModulation(1, 1, 1);

			local visible = util.PixelVisible(self:GetPos() + self:GetUp() * 3, 20, self.PixVis);

			if (!visible) then return; end;

			local alpha = math.Clamp((EyePos():Distance(self:GetPos()) / 10) * dot * visible, 0, 30);
			local newColor = Color((color.x / 2) * 255, (color.y / 2) * 255, (color.z / 2) * 255, alpha);

			render.SetMaterial(mat);
			render.DrawSprite(self:GetPos() + self:GetUp() * 2, 600, 600, newColor, visible * dot);
		end;

		self:DrawTranslucent2()
	end
end