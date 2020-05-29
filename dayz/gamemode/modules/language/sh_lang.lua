if SERVER then
   util.AddNetworkString("DZ_ServerLang")
   util.AddNetworkString("DZ_LangMsg")
end
---- Shared language stuff

-- tbl is first created here on both server and client
-- could make it a module but meh
if LANG then return end
LANG = {}

-- Add all lua files in our /lang/ dir
local dir = GM.FolderName or "dayz"
local files, dirs = file.Find(dir .. "/modules/language/lang/*.lua", "LUA" )
for _, fname in pairs(files) do
   local path = "lang/" .. fname
   -- filter out directories and temp files (like .lua~)
   if string.Right(fname, 3) == "lua" then
      util.IncludeClientFile(path)
      MsgN("Included DayZ language file: " .. fname)
   end
end


if SERVER then
   local count = table.Count

   -- Can be called as:
   --   1) LANG.Msg(ply, name, params)  -- sent to ply
   --   2) LANG.Msg(name, params)       -- sent to all
   --   3) LANG.Msg(role, name, params) -- sent to plys with role
   function LANG.Msg(arg1, arg2, arg3)
      if type(arg1) == "string" then
         LANG.ProcessMsg(nil, arg1, arg2)
      else
         LANG.ProcessMsg(arg1, arg2, arg3)
      end
   end

   function LANG.ProcessMsg(send_to, name, params)
      -- don't want to send to null ents, but can't just IsValid send_to because
      -- it may be a recipientfilter, so type check first
      if type(send_to) == "Player" and (not IsValid(send_to)) then return end

      -- number of keyval param pairs to send
      local c = params and count(params) or 0

      net.Start("DZ_LangMsg")
         net.WriteString(name)

         net.WriteUInt(c, 8)
         if c > 0 then

            for k, v in pairs(params) do
               -- assume keys are strings, but vals may be numbers
               net.WriteString(k)
               net.WriteString(tostring(v))
            end
         end

      if send_to then
         net.Send(send_to)
      else
         net.Broadcast()
      end
   end

   function LANG.MsgAll(name, params)
      LANG.Msg(nil, name, params)
   end

   CreateConVar("dz_lang_serverdefault", "english", FCVAR_ARCHIVE)

   local function ServerLangRequest(ply, cmd, args)
      if not IsValid(ply) then return end

      net.Start("DZ_ServerLang")
         net.WriteString(GetConVarString("dz_lang_serverdefault"))
      net.Send(ply)
   end
   concommand.Add("_dz_request_serverlang", ServerLangRequest)

else -- CLIENT

   local function RecvMsg()
      local name = net.ReadString()

      local c = net.ReadUInt(8)
      local params = nil
      if c > 0 then
         params = {}
         for i=1, c do
            params[net.ReadString()] = net.ReadString()
         end
      end

      LANG.Msg(name, params)
   end
   net.Receive("DZ_LangMsg", RecvMsg)

   LANG.Msg = LANG.ProcessMsg

   local function RecvServerLang()
      local lang_name = net.ReadString()
      lang_name = lang_name and string.lower(lang_name)
      if LANG.Strings[lang_name] then
         if LANG.IsServerDefault(GetConVarString("dz_language")) then
            LANG.SetActiveLanguage(lang_name)
         end

         LANG.ServerLanguage = lang_name

         print("Server default language is:", lang_name)
      end
   end
   net.Receive("DZ_ServerLang", RecvServerLang)
end

-- It can be useful to send string names as params, that the client can then
-- localize before interpolating. However, we want to prevent user input like
-- nicknames from being localized, so mark string names with something users
-- can't input.
function LANG.NameParam(name)
   return "LID\t" .. name
end
LANG.Param = LANG.NameParam

function LANG.GetNameParam(str)
   return string.match(str, "^LID\t([%w_]+)$")
end
