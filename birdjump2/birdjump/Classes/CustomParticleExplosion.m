//
//  CustomParticleExplosion.m
//  birdjump
//
//  Created by Eric on 12-11-15.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "CustomParticleExplosion.h"

@implementation CustomParticleExplosion
static CustomParticleExplosion* instance;
+(CustomParticleExplosion*)share{
    if (instance==nil) {
        instance= [[CustomParticleExplosion alloc]init];        
    }
    return instance;
}

-(CCParticleExplosion*)getEmitterByTexture:(NSString*) textureName{
    return [self getEmitterByTexture:textureName withNode:nil position:ccp(0, 0)];
}
-(CCParticleExplosion*)getEmitterByTexture:(NSString*) textureName withNode:(CCNode*)node position:(CGPoint) position{
    CCParticleExplosion* emitter = [[[CCParticleExplosion alloc] initWithTotalParticles:300]autorelease];
    CCTexture2D* texture= [[CCTextureCache sharedTextureCache] textureForKey:textureName];
    if (texture==nil) {
        [[CCTextureCache sharedTextureCache] addImage:textureName ];
    }
    emitter.texture=texture;
    if (node!=nil) {
        [node addChild:emitter z: zParticleExplosion];
        emitter.position=position;
    }
	return emitter;
}
@end
