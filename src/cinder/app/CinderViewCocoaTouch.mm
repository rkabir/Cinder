/*
 Copyright (c) 2010, The Barbarian Group
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that
 the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and
	the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
	the following disclaimer in the documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/


#include "cinder/app/CinderViewCocoaTouch.h"
#include "cinder/cocoa/CinderCocoa.h"

@implementation CinderViewCocoaTouch

@synthesize animating;
@dynamic animationFrameInterval;

// Set in initWithFrame based on the renderer
static Boolean sIsEaglLayer;

+ (Class) layerClass
{
	if( sIsEaglLayer )
		return [CAEAGLLayer class];
	else
		return [CALayer class];
}

- (id)initWithFrame:(CGRect)frame app:(ci::app::AppCocoaTouch*)app renderer:(ci::app::Renderer*)renderer
{
	// This needs to get setup immediately as +layerClass will be called when the view is initialized
	sIsEaglLayer = renderer->isEaglLayer();
	
	if( (self = [super initWithFrame:frame]) ) {
		animating = FALSE;
		animationFrameInterval = 1;
		displayLink = nil;
		mApp = app;
		mRenderer = renderer;
		renderer->setup( mApp, ci::cocoa::CgRectToArea( frame ), self );
		mApp->privateSetup__();
	}
	
    return self;
}

- (void) layoutSubviews
{
	CGRect bounds = [self bounds];
	mRenderer->setFrameSize( bounds.size.width, bounds.size.height );
	mApp->privateResize__( bounds.size.width, bounds.size.height );
	[self drawView:nil];	
}

- (void)drawRect:(CGRect)rect
{
	mRenderer->startDraw();
	mApp->privateUpdate__();
	mApp->privateDraw__();
	mRenderer->finishDraw();
}

- (void)drawView:(id)sender
{
	if( sIsEaglLayer ) {
		mRenderer->startDraw();
		mApp->privateUpdate__();
		mApp->privateDraw__();
		mRenderer->finishDraw();
	}
	else
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:self waitUntilDone:NO];
}

- (void) startAnimation
{
	if( ! animating ) {
		displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
		[displayLink setFrameInterval:animationFrameInterval];
		[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		
		animating = TRUE;
	}
}

- (void)stopAnimation
{
	if( animating ) {
		[displayLink invalidate];
		displayLink = nil;
		
		animating = FALSE;
	}
}

- (NSInteger) animationFrameInterval
{
	return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
	if ( frameInterval >= 1 ) {
		animationFrameInterval = frameInterval;
		
		if( animating ) {
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void)dealloc
{
    [super dealloc];
}

/////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers
- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	for( UITouch *touch in touches ) {
		std::cout << "Touched!" << std::endl;
		CGPoint pt = [touch locationInView:self];
		int mods = 0;
		mods |= cinder::app::MouseEvent::LEFT_DOWN;
		mApp->privateMouseDown__( cinder::app::MouseEvent( cinder::app::MouseEvent::LEFT_DOWN, pt.x, pt.y, mods, 0.0f, 0 ) );
	}
}

@end
