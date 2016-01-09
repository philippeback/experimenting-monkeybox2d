Strict

Import mojo
Import box2d.common
Import box2d.collision
Import box2d.dynamics

Function RadToDeg:Int(rad:Float)
	if rad <> 0.0 Then Return (rad * 180.0) / PI Else Return 0
End Function

Class CEntity
	Field bodyDef:b2BodyDef
	Field bodyShape:b2PolygonShape
	Field body:b2Body
	Field fixtureDef:b2FixtureDef
	Field img:Image
	
	Method CreateBox:Void(world:b2World, x:Float, y:Float, width:Float, height:Float, static:Bool = False)
		Self.fixtureDef	= New b2FixtureDef()
		Self.bodyShape	= New b2PolygonShape()
		Self.bodyDef	= New b2BodyDef()
		
		If static = True
			Self.bodyDef.type = b2Body.b2_staticBody
		Else
			Self.bodyDef.type = b2Body.b2_Body
		endif
		
		Self.fixtureDef.density		= 1.0
		Self.fixtureDef.friction	= 0.3
		Self.fixtureDef.restitution	= 0.1
		Self.fixtureDef.shape		= Self.bodyShape
		Self.bodyDef.position.Set(x, y)
		Self.bodyShape.SetAsBox(width, height)
		Self.body = world.CreateBody(Self.bodyDef)
		Self.body.CreateFixture(Self.fixtureDef)
		Self.bodyDef.allowSleep		= True
		Self.bodyDef.awake			= True
	End
	
	Method CreateImageBox:Void(world:b2World, img:Image, x:Float, y:Float, static:Bool = False)
		Self.img = img
		Self.img.SetHandle(Self.img.Width() / 2, Self.img.Height() / 2)
		Self.CreateBox(world, x, y, img.Width() / 2, img.Height() / 2, static)
	End
	
	Method SetFriction:Void(friction:Float = 0.5)
		Self.fixtureDef.friction = friction
		Self.body.CreateFixture(Self.fixtureDef)
	End
	
	Method SetDensity:Void(density:Float = 1.0)
		Self.fixtureDef.density = density
		Self.body.CreateFixture(Self.fixtureDef)
	End
	
	Method SetRestitution:Void(restitution:Float = 0.1)
		Self.fixtureDef.restitution = restitution
		Self.body.CreateFixture(Self.fixtureDef)
	End
	
	Method SetMass:Void(mass:Float)
		Local md:b2MassData = new b2MassData()
		Self.body.GetMassData(md)
		md.mass = mass
		Self.body.SetMassData(md)
	End
	
	Method SetImage:Void(img:Image)
		Self.img = img
	End
	
	Method Draw:Void(ratio:Float = 1.0)
		if Self.img <> Null
			Local x:Float	= self.body.GetPosition().x
			Local y:Float	= self.body.GetPosition().y
			Local r:Float	= RadToDeg(Self.body.GetAngle()) * -1
			
			DrawImage(Self.img, x, y, r, 1.0, 1.0, 0)
		EndIf
	End
End

Class CWorld
	Field world:b2World
	Field m_velocityIterations:int
	Field m_positionIterations:int
	Field m_timeStep:Float
	Field ratio:Float
	
	Field entities:List<CEntity>
	
	Method New(ratio:Float = 1.0, gravityX:Float = 0.0, gravityY:Float = 10.0)
		Self.ratio = ratio
		Self.world = New b2World(New b2Vec2(gravityX, gravityY), True)
		Self.world.SetGravity(new b2Vec2(gravityX, gravityY))
		
		Self.m_velocityIterations	= 3
		Self.m_positionIterations	= 3
		Self.m_timeStep				= 1.0 / 10.0
		
		Self.entities = New List<CEntity>()
	End
	
	Method update:Void()
		Self.world.TimeStep(self.m_timeStep, self.m_velocityIterations, self.m_positionIterations)
		Self.world.ClearForces()
	End
	
	Method render:Void()
		if Self.entities.Count() > 0
			For Local e:CEntity = eachin self.entities
				if e <> Null e.Draw(self.ratio)
			Next
		EndIf
	End
	
	Method CreateBox:CEntity(x:Float, y:Float, width:Float, height:Float, static:Bool = false)
		Local entity:CEntity = new CEntity()
		entity.CreateBox(Self.world, x, y, width, height, static)
		Self.entities.AddLast(entity)
		
		Return entity
	End
	
	Method CreateImageBox:CEntity(img:Image, x:Float, y:Float, static:Bool = False)
		Local entity:CEntity = new CEntity()
		entity.CreateImageBox(Self.world, img, x, y, static)
		Self.entities.AddLast(entity)
		
		Return entity
	End
End

Class CTest extends App
	Field world:CWorld
	Field player:Image
	Field playerEntity:CEntity
	Field groundEntity:CEntity
	Field ratio:Float
	
	Method OnCreate:Int()
		Self.ratio			= 640.0 / DeviceWidth()
		Self.world 			= New CWorld(Self.ratio)
		Self.player			= LoadImage("player.png")
		Self.groundEntity	= Self.world.CreateBox(0, DeviceHeight() - 10, DeviceWidth(), 10, True)
		
		SetUpdateRate(60)
		
		Return 0
	End
	
	Method OnUpdate:Int()
		Self.world.update()
		
		if MouseHit() Or TouchHit()
			Local mx:Float	= MouseX()
			Local my:Float	= MouseY()
			Local e:CEntity = self.world.CreateImageBox(self.player, mx, my)
			e.body.SetAngularVelocity(Rnd(-0.1, 0.1))
			
		EndIf
		Return 0
	End
	
	Method OnRender:Int()
		Cls(90, 120, 200)
		#if TARGET = "android"
		DrawText("touch to spwan a new crate", DeviceWidth() / 2, 20, 0.5)
		#Else
		DrawText("left click to spwan a new crate", DeviceWidth() / 2, 20, 0.5)
		#EndIf
		
		Self.world.render()
		
		Return 0
	End
End

Function Main:Int()
	New CTest()
	Return 0
End