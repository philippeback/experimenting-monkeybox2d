'A Simplfield Demo Assamabled from Other Demos Thanks to Volker and muddy_shoes and my own style as well.

'Shows In Real Basic Way how Box2D Engine works.
'Any one who see a place for corrections in the code and new Remarks
'Is free to do it and republish. All in good of helping the new guys around here.
'If you find this demo usufale I will be glad to know and will be encorouged to make more demos of that sort for begginers among this community (Like me)


'----Includes----'
Import box2d.collision
Import box2d.collision.shapes
Import box2d.common.math
Import box2d.dynamics.contacts
Import box2d.dynamics
Import box2d.flash.flashtypes
Import box2d.common.math.b2vec2

'----Test Zone----'
Function Main()
	New Box2DLoop
End Function

'----Main Loop----'
Class Box2DLoop Extends App

	'Box 2D Parameters Set
	Field BXworld				: b2World					'Box2D physical World Object
	Field m_velocityIterations	: int 	= 10				'Dont know whats this yet.
	Field m_positionIterations	: int 	= 10				'Either that.
	Field m_timeStep			: Float = 1.0/60			'Hmm, I know whats this but no changes accured when presetting.
	Field m_physScale			: Float = 1 ' 30       		'I Change its value but same results.
	Field m_debugdrawscale		: Float	= 10	 			'This Affects the size of the physical Body Display
			
	Field b:b2Body 			      'A phsyical body Type of box2d decleration.
	
	
	'--Main Methods----'
	
	Method OnCreate()
	
		'Box2D Setups
		Local doSleep:Bool = True
			  
		'Creating a new Box2D World
		BXworld = New b2World(New b2Vec2(0,0),doSleep)
		SetGravity(0.0,9.7)
		
		'Creating a Ground Box
		'From some reason, if you dont create this ground box nothing works...
		b=self.CreateBox(0,40,70,2)
		b.SetUserData(New StringObject("ground")) 'give object a name for collision detection in contactlistener
		
		'Display Setup
		SetUpdateRate(60)
		
		'Box2D Debug Settings   		'Delete this section if you dont need to see the physical process in graphics.
		Local dbgDraw :b2DebugDraw = New b2DebugDraw()
		dbgDraw.SetDrawScale(m_debugdrawscale)
		dbgDraw.SetFillAlpha(0.3)
		dbgDraw.SetLineThickness(1.0)
		dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)'| b2DebugDraw.e_pairBit)
		BXworld.SetDebugDraw(dbgDraw)
		
	End Method
	
	Method OnRender()
		Cls
		
		'Box2D Display Section
		BXworld.DrawDebugData() 'Delete this line if you dont need to see the physical process in graphics. (must also delete 'Box2D Debug Settings section above)
				 
		'(Mojo commands must come only after the Box2D Debug Draw or it wont be seeing)
		 
		'Mojo Display Section
		SetColor 255,255,255
		DrawText 	"Obj X Position: "+b.GetPosition.x*10,5,425
		DrawText 	"Obj Y Position: "+b.GetPosition.y*10,5,440
		  
		DrawText "Press Mouse Button to create a new Sphere",5,458
		  
	End Method
	
	Method OnUpdate()
					
		'The Stepping of Box2D Engine
		BXworld.TimeStep(m_timeStep,m_velocityIterations,m_positionIterations)
		BXworld.ClearForces()	'Dont know why you need this..
				
		'Add a new Sphere
		If( MouseHit( MOUSE_LEFT) )
			b=Self.CreateSphere(MouseX()/10,MouseY()/10,4)	'Creates a new Physical Sphere.
			b.SetUserData(New StringObject("sphere"))		'Dont know what this for.
			
			Print "A New Sphere Created"
		End
	End Method
	
	'------------Create Sphere,Box And Set Gravity Functions-----------------------------'
	
	Method CreateSphere:b2Body (xpos:Float,ypos:Float,radius:Float,static:Bool=false)	'Creates a Physical Sphere
		Local fd :b2FixtureDef = New b2FixtureDef()
		Local bd :b2BodyDef = New b2BodyDef()
		Local cd :b2CircleShape = New b2CircleShape()
		'
		cd.m_radius  = radius
		fd.density = 2
		fd.restitution = 0.2
		fd.friction = 0.5
		fd.shape=cd
		if static=true
			bd.type = b2Body.b2_staticBody ' a static body
		else
			bd.type = b2Body.b2_Body 'a dynamic body
		endif
		bd.position.Set(xpos,ypos)
		Local b :b2Body
		b = self.BXworld.CreateBody(bd)
		b=Self.BXworld.CreateBody(bd)
		b.CreateFixture(fd)
		Return b
	End Method
	
	Method CreateBox:b2Body (xpos:Float,ypos:Float,width:Float,height:Float,static:Bool=true)	'Creates a Physical Box
		Local fd :b2FixtureDef = New b2FixtureDef()
		Local sd :b2PolygonShape = New b2PolygonShape()
		Local bd :b2BodyDef = New b2BodyDef()
		if static=true
			bd.type = b2Body.b2_staticBody
		else
			bd.type = b2Body.b2_Body
		endif
		fd.density = 1.0
		fd.friction = 0.5
		fd.restitution = 0.1
		fd.shape = sd
		sd.SetAsBox(width,height)
		bd.position.Set(xpos,ypos)
		Local b :b2Body
		b = self.BXworld.CreateBody(bd)
		b.CreateFixture(fd)
		'
		Return b
	End Method
	
	Method SetGravity:Void(x:Float,y:Float)	'An easier Method to setup gravity
		Self.BXworld.SetGravity(New b2Vec2(x,y))
	End Method
	
End Class