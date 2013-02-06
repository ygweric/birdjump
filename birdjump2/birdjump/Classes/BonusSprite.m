//
//  CoinSprite.m
//  birdjump
//
//  Created by Eric on 12-11-8.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "BonusSprite.h"

@implementation BonusSprite
@synthesize bonusType;
+ (id) BonusWithinLayer:(CCNode *)layer bType:(BonusType)bType bTag:(int)bTag{

    CCSpriteBatchNode *spriteSheet = (CCSpriteBatchNode*)[layer getChildByTag:tBonusManager];
    NSArray* animFrameNames= [self getAnimFrameByBonusType:bType];
    BonusSprite* bonusSprite=[BonusSprite spriteWithSpriteFrameName:[animFrameNames objectAtIndex:0]];
    bonusSprite.bonusType=bType;
    CCAction* action=[self createAnimationWithFrameNames:animFrameNames];
    [bonusSprite runAction:action];
    [spriteSheet addChild:bonusSprite z:zBonus tag:bTag];
    return bonusSprite;
}
+ (NSArray *)getAnimFrameByBonusType:(int)bType {
    NSArray *animFrameNames=nil;
    switch (bType) {
        case tBlockBounce:
            animFrameNames =[NSArray arrayWithObjects:
                             @"block-bounce-sky01.png",
                             @"block-bounce-sky02.png",
                             @"block-bounce-sky03.png",
                             nil];
            break;
        case tBlockBreak:
            animFrameNames =[NSArray arrayWithObjects:
                             @"block-break-sky01.png",
                             @"block-break-sky02.png",
                             nil];
            break;
        case tBlockSpike:
            animFrameNames =[NSArray arrayWithObjects:
                             @"block-spike-sky.png",
                             nil];
            break;
        case tCoinGold:
            animFrameNames =[NSArray arrayWithObjects:
                             @"coin02_0000.png",
                             @"coin02_0001.png",
                             @"coin02_0002.png",
                             @"coin02_0003.png",
                             @"coin02_0004.png",
                             nil];
            break;
        case tCoinTrick:
            animFrameNames =[NSArray arrayWithObjects:
                             @"coin_trick01_0000.png",
                             @"coin_trick01_0001.png",
                             @"coin_trick01_0002.png",
                             @"coin_trick01_0003.png",
                             @"coin_trick01_0004.png",
                             @"coin_trick01_0005.png",
                             nil];
            break;
        case tCoinTrickParticle:
            animFrameNames =[NSArray arrayWithObjects:
                             @"lb-particle-mega-01.png",
                             @"lb-particle-mega-02.png",
                             @"lb-particle-mega-03.png",
                             nil];
            break;
        default:
            NSLog(@"other !! BonusType:%d",bType);
            break;
    }
    return animFrameNames;
}

+(CCAction*)getActionByBonusType:(int)bType{
     NSArray* animFrameNames = [self getAnimFrameByBonusType:bType];
   CCAction* action=[self createAnimationWithFrameNames:animFrameNames];
    return action;
}

+(CCAction*)createAnimationWithFrameNames:(NSArray*) animFrameNames{
    NSMutableArray* animFrames=[NSMutableArray arrayWithCapacity:3];
    int i=0;
    while (i<animFrameNames.count) {
        [animFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[animFrameNames objectAtIndex:i]]];
        i++;
    }
    //4)创建动画对象
    CCAnimation *anim = [CCAnimation
                         animationWithFrames:animFrames delay:0.2f];
     return [CCRepeatForever actionWithAction:
              [CCAnimate actionWithAnimation:anim restoreOriginalFrame:NO]];

}
+(void)initSpriteSheet:(CCNode*)layer texture:(CCTexture2D*) texture{
    if (texture) {
        //Adds multiple Sprite Frames from a plist file. The texture will be associated with the created sprite frames.
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"layer_award.plist" texture:texture ];
    }else{
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"layer_award.plist" ];
    }
    
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode
                                      batchNodeWithFile:@"layer_award.png"];
    //这里tCharacterManager的z要在tSpriteManager之上，这样此才不会被覆盖
    [layer addChild:spriteSheet z:zBonusSpriteSheet tag:tBonusManager];
}
+(void)initSpriteSheet:(CCNode*)layer{
    [self initSpriteSheet:layer texture:nil];
}


@end
