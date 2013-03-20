//
//  BirdSprite.h
//  birdjump
//
//  Created by Eric on 12-11-4.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//


#import "GameLayer.h"
#define MAX_GRADE 5

@interface BirdSprite : CCSprite{
    CCLayer* gLayer;
    
}

@property ccVertex2F vel; //速度
@property ccVertex2F acc; //加速度

@property (nonatomic,retain) CCParticleSystem* trick_particles;

@property (nonatomic,retain) CCAction* normalAction;
@property (nonatomic,retain) CCAction* upAction;
@property (nonatomic,retain) CCAction* downAction;
@property (nonatomic,retain) GameLayer* layer;
//当前主角等级，从1开始
@property  int currentGrade;
+ (id) BirdWithinLayer:(CCLayer *)layer;

-(void)upgradeBird;

- (void)birdEmitterInit;
-(void)changeMoveDirection:(bool)isUp;

-(void)resetParticleSystem;
-(void)stopParticleSystem;

+(void)initSpriteSheet:(CCNode*)layer;
- (void) changePositon:(CCLayer *)layer xStep:(float)xStep yStep:(float)yStep;
@end
