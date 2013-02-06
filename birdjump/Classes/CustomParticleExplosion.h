//
//  CustomParticleExplosion.h
//  birdjump
//
//  Created by Eric on 12-11-15.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "CCParticleExamples.h"

@interface CustomParticleExplosion : CCParticleExplosion
+(CustomParticleExplosion*)share;
-(CCParticleExplosion*)getEmitterByTexture:(NSString*) textureName;
-(CCParticleExplosion*)getEmitterByTexture:(NSString*) textureName withNode:(CCNode*)node position:(CGPoint) position;
@end
