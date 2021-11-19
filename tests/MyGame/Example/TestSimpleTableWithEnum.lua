--[[ MyGame.Example.TestSimpleTableWithEnum

  Automatically generated by the FlatBuffers compiler, do not modify.
  Or modify. I'm a message, not a cop.

  Generated on : 2021-11-19T14:40:30-0800
  flatc version: 2.0.0

  Declared by  : //monster_test.fbs
  Rooting type : MyGame.Example.Monster (//monster_test.fbs)

--]]

local flatbuffers = require('flatbuffers')

local TestSimpleTableWithEnum = {}
local mt = {}

function TestSimpleTableWithEnum.New()
  local o = {}
  setmetatable(o, {__index = mt})
  return o
end

function mt:Init(buf, pos)
  self.view = flatbuffers.view.New(buf, pos)
end

function mt:Color()
  local o = self.view:Offset(4)
  if o ~= 0 then
    return self.view:Get(flatbuffers.N.Uint8, self.view.pos + o)
  end
  return 2
end

function TestSimpleTableWithEnum.Start(builder)
  builder:StartObject(1)
end

function TestSimpleTableWithEnum.AddColor(builder, color)
  builder:PrependUint8Slot(0, color, 2)
end

function TestSimpleTableWithEnum.End(builder)
  return builder:EndObject()
end

return TestSimpleTableWithEnum