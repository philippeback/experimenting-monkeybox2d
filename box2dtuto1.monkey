'----Includes----'
Import box2d.dynamics.b2world

'----Test Zone----'
Function Main()
	New Box2DLoop()
End Function

'----Main Loop----'
Class Box2DLoop Extends App

	Field _world:b2World

	Field RATIO:Float = 8
	
	Field _nextCrateIn:Int
	
	
	
	'--Main Methods----'
	
	Method OnCreate()
	
		' 1. Set Up World
		setupWorld()
		' Create Walls and Floors
		createWallsAndFloor()
		setupDebugDraw()
		_nextCrateIn = 0
		
	
		'Display Setup
		SetUpdateRate(60)
		

			  
	End Method
	
	Method setupDebugDraw:Void()
	
	
	    
		'Box2D Debug Settings   		'Delete this section if you dont need to see the physical process in graphics.
		Local dbgDraw :b2DebugDraw = New b2DebugDraw()
	    
		dbgDraw.SetDrawScale(10.0)
		dbgDraw.SetFillAlpha(0.3)
		dbgDraw.SetLineThickness(1.0)
		dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)'| b2DebugDraw.e_pairBit)
		_world.SetDebugDraw(dbgDraw)
		
	End
	Method OnRender()
		Cls
		
		_world.DrawDebugData()
		  
	
		
	End Method
	
	Method OnUpdate()
					
		_world.TimeStep(1.0 /30,10,10)
		_world.ClearForces()
		
		_nextCrateIn = _nextCrateIn - 1
		
		if _nextCrateIn  <=0 And _world.m_bodyCount < 80 Then
			addARandomCrate()
			_nextCrateIn = 10
		EndIf
		
	End Method
	
	
	Method setupWorld()
	
		
		
		' Define gravity
		Local gravity:b2Vec2 = new b2Vec2(0,9.8)
		
		' Ignore Sleeping Objects
		Local ignoresleeping:Bool = true
		
		_world = New b2World(gravity,ignoresleeping)

		
		
		
	End
	
	Method addARandomCrate()
		Local fd:b2FixtureDef = new b2FixtureDef()
		Local sd:b2PolygonShape = new b2PolygonShape()
		Local bd:b2BodyDef = new b2BodyDef();
		bd.type = b2Body.b2_Body
		
		fd.friction = 0.8
		fd.restitution = 0.3
		fd.density = 0.7
		fd.shape = sd
		
		sd.SetAsBox(randomInt(5,40) / RATIO, randomInt(5, 40) / RATIO)
		
		bd.position.Set(randomInt(15,530) / RATIO, randomInt(-100, -10) / RATIO)
		bd.angle = randomInt(0,360) * 3.14 / 180
		
		Local b:b2Body = _world.CreateBody(bd)
		b.CreateFixture(fd)
	
	End
	
	Method randomInt:Int(lowVal:Int, highVal:Int)
		
		if (lowVal <= highVal)
			
			Return lowVal + Floor(Rnd() * (highVal - lowVal + 1))
			
		EndIf
	End
	
	Method createWallsAndFloor:Void()
		
		Local sd:b2PolygonShape = new b2PolygonShape()
		Local fd:b2FixtureDef = new b2FixtureDef()
		Local bd:b2BodyDef = new b2BodyDef()
		bd.type = b2Body.b2_staticBody
		
		sd.SetAsArray([New b2Vec2(0,0),New b2Vec2(550/RATIO,0), New b2Vec2(550/RATIO,10/RATIO), New b2Vec2(0,10/RATIO)])
			
	
		fd.friction = 0.5
		fd.restitution = 0.3
		fd.density = 0.0
		fd.shape = sd
		
		bd.position.Set(0,560/RATIO)
		
		Local b:b2Body = _world.CreateBody(bd)
		b.CreateFixture(fd)
		
		Local sdwall:b2PolygonShape = new b2PolygonShape()
		Local fdwall:b2FixtureDef = new b2FixtureDef()
		Local bdwall:b2BodyDef = new b2BodyDef()
		bd.type = b2Body.b2_staticBody
		
		fdwall.friction =  0.5
		fdwall.restitution = 0.3
		fdwall.density = 0
		fdwall.shape = sdwall
		sdwall.SetAsBox(5/RATIO,390/RATIO)
		
		bdwall.position.Set(5/RATIO,195/RATIO)
		
		Local leftwall:b2Body = _world.CreateBody(bdwall)
		leftwall.CreateFixture(fdwall)
		
		bdwall.position.Set(545/RATIO,195/RATIO)
		
		Local rightwall:b2Body = _world.CreateBody(bdwall)
		rightwall.CreateFixture(fdwall)

		
		
	End
End Class