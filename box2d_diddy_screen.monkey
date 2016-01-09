Strict 
Import diddy 
Import box2d.collision
Import box2d.collision.shapes
Import box2d.collision.shapes
Import box2d.dynamics.joints
Import box2d.common.math
Import box2d.dynamics.contacts
Import box2d.dynamics
Import box2d.flash.flashtypes
Import box2d.common.math.b2vec2
Import box2d.dynamics.controllers 

Global gameScreen:Screen

Const FRAMERATE:= 60
Const PHYSICS_SCALE_PIXELS_PER_METER:= 64

Function Main:Int()
	New MyGame()
	Return 0
End Function

Class MyGame Extends DiddyApp

	Method OnCreate:Int()
		Super.OnCreate()
		' default is 60 already, no need to change this
		diddyGame.FPS = FRAMERATE	' set the update rate for Diddy. 60 is standard. Just here for demonstration.
		
		gameScreen = new Box2dscreen  
		gameScreen.PreStart()		
		Return 0
	End
	
End


Class Box2dscreen extends Screen
	'
	Field world:b2World 
	Field contactlistener:ContactListener 
	'
    Field m_velocityIterations:int = 6
    Field m_positionIterations:int = 2
	'Physics simulation timestep. If the code can't match the speed, we'll see slow motion.
    Field m_timeStep:Float = 1.0 / FRAMERATE 	  ' set this to your SetUpdateRate()
    Field m_physScale:Float = PHYSICS_SCALE_PIXELS_PER_METER	    ' Not in use, but you should not use pixels as your units,
										' an object of length 200 pixels would be seen by Box2D as the size of 
										' a 45 story building.
										
	Field m_debugdrawscale:Float = PHYSICS_SCALE_PIXELS_PER_METER	' set this to m_physScale if you are scaling your world.
	
	
	Method New()
		Local doSleep:Bool = True

		Self.world = New b2World(New b2Vec2(0, 0), doSleep)	' no need for AABB in newer versions of box2d, the world is infinite
		Self.SetGravity(0.0,10) '
		world.SetWarmStarting(True)	
		'
		'
		'// set debug draw
		Local dbgDraw :b2DebugDraw = New b2DebugDraw()       

		dbgDraw.SetDrawScale(m_debugdrawscale)
		dbgDraw.SetFillAlpha(0.3)
		dbgDraw.SetLineThickness(1.0)
		dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)'| b2DebugDraw.e_pairBit)
		world.SetDebugDraw(dbgDraw)
		Self.contactlistener=New ContactListener() 
		world.SetContactListener(Self.contactlistener)' for collision detection, if you need information which objects collide
				
	End Method
	
	Method Start:Void()
		diddyGame.screenFade.Start(50, False) ' just a fading effect
		Self.CreateDemo()
'		Self.CreateControllerDemo() ' uncomment this for a demo of controllers
	End
	
	Method Render:Void()
		Cls
		self.world.DrawDebugData()
	End

	Method Update:Void()
		world.TimeStep(m_timeStep, m_velocityIterations, m_positionIterations)
		world.ClearForces()
		If KeyHit(KEY_ESCAPE)
			game.screenFade.Start(50, True)
			game.nextScreen = game.exitScreen
		End
	End Method
	
	Method SetGravity:Void(x:Float,y:Float)
		Self.world.SetGravity(New b2Vec2(x,y))

	End Method
	
	Method CreateControllerDemo:Void()
		' uncomment the line 'Self.CreateControllerDemo()' in Method Start() to see this running.
		'
		' accelration controllers are good to simulate wind, or if some bodies shall fall faster then others.
		local accelcontroller:b2ConstantAccelController=new b2ConstantAccelController  ' create an acceleration controller
		accelcontroller.A=New b2Vec2(0,50) ' Set force.  Every body added to Controller will be accelerated by this vector (box2d does this, just fire and forget).
		world.AddController(accelcontroller) ' add controller to world
		' add a body to controller. This body will fall faster then all others, because he is accelerated on the y-axis.
		Local box:b2Body=self.CreateBox(600,100,20,20,false)
		accelcontroller.AddBody(box)
		'
		' a gravitycontroller, good to simulate gravity between objects or magnetism.
		local gravitycontroller:b2GravityController=new b2GravityController 
		gravitycontroller.G=15 ' the force with which the bodies attract each other.
		world.AddController(gravitycontroller)
		Local anotherbox:b2Body=self.CreateBox(510,100,30,10,false) ' add two bodies.
		Local lastbox:b2Body=self.CreateBox(410,100,30,10,false)    ' This bodies will attract each other like 'planets', they have their own gravity.
		gravitycontroller.AddBody(anotherbox) ' add bodies to controller
		gravitycontroller.AddBody(lastbox) 'call controller.RemoveBody() to stop a controller affecting a body.
		
	End Method
	
	Method CreateDemo:Void()
		Local b:b2Body 
		' a box for ground
		b=Self.CreateBox(340,420,480,30,true)
		
		b.SetUserData(New StringObject("ground")) ' give object a name for collision detection in contactlistener
		' a sphere
		b=Self.CreateSphere(350,220,40)
		b.SetUserData(New StringObject("sphere"))
		' create a polygon from an array of b2d Vectors
		Local tri:b2Vec2[]= [New b2Vec2(0, 0), New b2Vec2(0, -100),   New b2Vec2(200 ,0)]
		b=Self.CreatePolybody(200,20,tri)
		b.SetUserData(New StringObject("triangle1"))					
'		' create a polygon from an array with floats
		Local triangle:Float[]=[0.000000000,-49.000000,99.000000,59.0000000,-77.000000,79.0000000]
		b=Self.CreatePolybody(200,100,Self.ArrayToVectorarray(triangle))
		b.SetUserData(New StringObject("triangle2"))	
	End Method
	
	Method CreateBox:b2Body (xpos:Float,ypos:Float,width:Float,height:Float,static:Bool=true)
		Local fd :b2FixtureDef = New b2FixtureDef()
		Local sd :b2PolygonShape = New b2PolygonShape()
		Local bd :b2BodyDef = New b2BodyDef()
		if static=true
			bd.type = b2Body.b2_staticBody
		else
			bd.type = b2Body.b2_Body
		endif		
		fd.density = 2.0
		fd.friction = 0.5
		fd.restitution = 0.4
		fd.shape = sd
		sd.SetAsBox(width / m_physScale, height / m_physScale)
		bd.position.Set(xpos / m_physScale, ypos / m_physScale)
		Local b :b2Body
		b = self.world.CreateBody(bd)		
		' Recall that shapes don?t know about bodies and may be used independently of the physics simulation. Therefore Box2D provides the b2Fixture class to attach shapes to bodies.
		b.CreateFixture(fd)	
		'
		Return b	
	End Method

	Method CreateSphere:b2Body (xpos:Float,ypos:Float,radius:Float,static:Bool=false)
		Local fd :b2FixtureDef = New b2FixtureDef()
		Local bd :b2BodyDef = New b2BodyDef()
		Local cd :b2CircleShape = New b2CircleShape()	  
		'		
		cd.m_radius = radius / m_physScale
		fd.density = 2
		fd.restitution = 0.2
		fd.friction = 0.5
		fd.shape=cd
		if static=true
			bd.type = b2Body.b2_staticBody ' a static body
		else
			bd.type = b2Body.b2_Body 'a dynamic body
		endif
		bd.position.Set(xpos / m_physScale, ypos / m_physScale)
		Local b :b2Body
		b=Self.world.CreateBody(bd)
		b.CreateFixture(fd) 			
		Return b	
	End Method
	
	Method CreatePolybody:b2Body(xpos:Float,ypos:Float,verts:b2Vec2[],static:Bool=false,bullet:Bool=false)
		' polys must be  defined vertices from left to right or their collision will not work. They must be convex.
		' A polygon is convex when all line segments connecting two points in the interior do not cross any edge
		' of the polygon. 
		' Polygons are solid and never hollow. A polygon must have 3 or more vertices.

		
		Local b :b2Body
		Local fd :b2FixtureDef = New b2FixtureDef()
		Local sd :b2PolygonShape = New b2PolygonShape()
		Local bd:b2BodyDef = New b2BodyDef()
		
 		For Local v:= EachIn verts
 			v.Multiply(1.0 / m_physScale)
		Next
		sd.SetAsArray(verts,verts.Length)
		fd.shape=sd
		bd.type = b2Body.b2_Body		
		
		bd.position.Set(xpos / m_physScale, ypos / m_physScale)
		bd.bullet=bullet
		b=Self.world.CreateBody(bd)
		
		fd.density = 1.0 
		fd.friction = 0.5
		fd.restitution = 0.1
		b.CreateFixture(fd)
				
		Return b		
	End Method
	
	Method ArrayToVectorarray:b2Vec2[](arr:Float[])
		' converts a normal array with floats to an array of b2Vec2
		Local vecs:b2Vec2[1]
		vecs=vecs.Resize(arr.Length/2)
		Local count:int
		For Local f:Float=0 to arr.Length-2 step 2
			vecs[count]=new b2Vec2(arr[f],arr[f+1])
			count+=1
		Next
		Return vecs
	End Method
		
	Method Cleanup:Void()
		' When a world leaves scope or is deleted by calling delete on a pointer, all the memory reserved for bodies, fixtures, and joints is freed.
		' This is done to improve performance and make your life easier. However, you will need to nullify any body, fixture, or joint pointers you have because they will become invalid.
	
	End Method
End Class

Class ContactListener Extends b2ContactListener
    ' to gather information about collided objects.
	' http://www.box2dflash.org/docs/2.1a/reference/Box2D/Dynamics/b2ContactListener.html
	' You cannot create/destroy Box2D entities inside these callbacks.
	
    Method New()
        Super.New()
    End
    
    Method PreSolve : void (contact:b2Contact, oldManifold:b2Manifold)
		

    End
	
	Method BeginContact:void(contact:b2Contact)
'		Print "objects did collide.."
		'
		' get the fixtures involved in collision
		Local fixA:b2Fixture=contact.GetFixtureA()' Instead of telling you which b2Body collided, the b2Contact tells you which fixture collided. 
		Local fixB:b2Fixture=contact.GetFixtureB()' To know which b2Body was involved in the collision you can retrieve a reference to the fixture.
		Local userdata1:Object=Object(fixA.GetBody().GetUserData()) 
		Local userdata2:Object=Object(fixB.GetBody().GetUserData()) 
		if userdata1<>NULL
			Local name:String=StringObject(userdata1).ToString()
'			Print "involved in collision:"+ name
		EndIf
		if userdata2<>NULL
			Local name:String=StringObject(userdata2).ToString()
'			Print "involved in collision:"+ name
		EndIf		
	End Method
	
End