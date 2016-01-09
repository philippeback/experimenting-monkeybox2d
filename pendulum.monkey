' pendulum.monkey

' F1 - reset
' F2 - add ball

Strict

Import mojo
Import box2d.collision
Import box2d.dynamics.joints

Const FRAMERATE:Int = 30

Const TIMESTEP:Float = 1.0 / FRAMERATE

'Iterations for solvers (velocity solver and position solver)
'L
Const VELOCITY_ITERATIONS:Int = 6
Const POSITION_ITERATIONS:Int = 3

'Divide pixel coordinates by this to have the World coordinates.
'If 1 pixel is one meter, this is making huge objects and all looks like slow.
'A good rule is 1 meter = 128 pixels, so, divide pixel measures by 128

Const PHYS_SCALE:Float = 128.0
Const SCREEN_WIDTH:= 1024
Const SCREEN_HEIGHT:= 768

Const SCREEN_WIDTH2:= 1024 / 2
Const SCREEN_HEIGHT2:= 768 / 2

Function toBoxCoords:b2Vec2(userUnitsVec:b2Vec2)

	Return New b2Vec2( (SCREEN_WIDTH2 + userUnitsVec.x) / PHYS_SCALE, (SCREEN_HEIGHT2 + userUnitsVec.y) / PHYS_SCALE)
	
End

Function toRelativeBoxCoords:b2Vec2(userUnitsVec:b2Vec2)

	Return New b2Vec2(userUnitsVec.x / PHYS_SCALE, userUnitsVec.y / PHYS_SCALE)
	
End


Class PendulumWorld

	Field world:b2World
	
	
	
	Method New()
		Init()
	End

	Method Init:Void()
	
		' Allow bodies to sleep
		Local doSleep:Bool = True
		
		Local gravity:b2Vec2 = New b2Vec2(0, 10)
		
		' Construct a world object
		world = New b2World(gravity, doSleep)
		world.SetWarmStarting(True)
		
		Local dbgDraw:= New DebugDraw()
		
		'This affects the way things are drawn scale wise.
		dbgDraw.SetDrawScale(PHYS_SCALE)
		
		dbgDraw.SetFillAlpha(0.90)
		dbgDraw.SetLineThickness(1.0)
		dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)'| b2DebugDraw.e_pairBit)
		world.SetDebugDraw(dbgDraw)
	End
	
	Method Update:Void()
		world.TimeStep(TIMESTEP, VELOCITY_ITERATIONS, POSITION_ITERATIONS)
		world.ClearForces()
	End
		
	Method Draw:Void()
		world.DrawDebugData()
		
	End

	Global FixtureDef:=New b2FixtureDef()
	Global BodyDef:=New b2BodyDef()
	Global Impulse:=New b2Vec2
		
	'Pass coordinates in screen pixels relative to screen center
	Method CreateBody:b2Body(x:Float, y:Float, bodytype:Int)
		BodyDef.type = bodytype
		BodyDef.fixedRotation=False
		BodyDef.position.Set( (SCREEN_WIDTH2 + x) / PHYS_SCALE, (SCREEN_HEIGHT2 + y) / PHYS_SCALE)
		Return world.CreateBody(BodyDef)
	End
	
	
	Method AddRadialFixture:b2Fixture(body:b2Body, r:Float, bits:Int, mask:Int)
		FixtureDef.shape = New b2CircleShape(r / PHYS_SCALE)
		FixtureDef.density=10
		FixtureDef.filter.categoryBits=bits
		FixtureDef.filter.maskBits=mask
		Local fixture:=body.CreateFixture(FixtureDef)
		fixture.SetRestitution(0.1)
		fixture.SetFriction(0.9)
		Return fixture
	End

	Method AddSquareFixture:b2Fixture(body:b2Body, w:Float, h:Float, bits:Int, mask:Int)
		Local shape:=New b2PolygonShape
		shape.SetAsBox w / PHYS_SCALE, h / PHYS_SCALE
		FixtureDef.shape=shape
		FixtureDef.density=10
		FixtureDef.filter.categoryBits=bits
		FixtureDef.filter.maskBits=mask
		Local fixture:=body.CreateFixture(FixtureDef)
		fixture.SetRestitution(0.1)
		fixture.SetFriction(0.9)
		Return fixture
	End
	
	Method ApplyImpulse:Void(body:b2Body, x:Float, y:Float)
		Impulse.x=x
		Impulse.y=y
		body.ApplyForce Impulse,body.GetPosition()
	End

End

Class DebugDraw Extends b2DebugDraw
	Method Clear:Void()
	End
End


Const STATICBIT%=1
Const DYNAMICBIT%=2

Class PendulumApp Extends App


	
	Field world:PendulumWorld
	Field renderCount:Int
	Field ground:b2Body
	Field pendulumBall:b2Body
	Field pendulumShaft:b2Body
	Field jointDef:b2DistanceJointDef
	Field joint:b2Joint

	Method OnCreate%()
		ResetWorld
		AddStuff
		SetUpdateRate FRAMERATE
		Return 0
	End
	
	Method ResetWorld:Void()
		world = New PendulumWorld
		
		ground = world.CreateBody(0, 220, b2Body.b2_staticBody)
		world.AddSquareFixture(ground, 100, 10, STATICBIT, DYNAMICBIT)
	End
	
	Method AddStuff:Void()
		pendulumBall = world.CreateBody(0, 0, b2Body.b2_Body)
		pendulumShaft = world.CreateBody(0, -100, b2Body.b2_Body)
		
		world.AddRadialFixture(pendulumBall, 20, DYNAMICBIT, STATICBIT | DYNAMICBIT)
		world.AddSquareFixture(pendulumShaft, 2, 100, DYNAMICBIT, STATICBIT | DYNAMICBIT)
		
		jointDef = New b2DistanceJointDef()
		
		' http://www.iforce2d.net/b2dtut/joints-revolute
		jointDef.Initialize(
			pendulumBall,
			pendulumShaft,
			toBoxCoords(New b2Vec2(0, 0)),
			toBoxCoords(New b2Vec2(0, 0)))
			
		jointDef.collideConnected = False
		jointDef.frequencyHz = 1.0
		jointDef.dampingRatio = 1.0
		
		joint = world.world.CreateJoint(jointDef)
		
		world.ApplyImpulse(pendulumBall, 1, 0)
	End
	
	Method OnUpdate%()
		If KeyHit(KEY_F1) ResetWorld
		If KeyHit(KEY_F2) AddStuff
		If KeyHit(KEY_ESCAPE)
			EndApp()
		End
		world.Update
		Return 0
	End

	Method OnRender%()
		renderCount+=1
		Cls 10,30,160
		world.Draw
		Return 0
	End
End

Function Main%()
	New PendulumApp
	Return 0
End