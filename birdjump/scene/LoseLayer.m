//
//  LoseLayer.m
//  birdjump
//
//  Created by Eric on 12-11-21.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "LoseLayer.h"
#import "MenuLayer.h"
#import "GameLayer.h"

@implementation LoseLayer
+(CCScene*)scene{
    CCScene* sc=[CCScene node];
    LoseLayer* la=[LoseLayer node];
    [sc addChild:la];
    return  sc;
}

-(id) init
{
	[super init];
    if ([SysConfig needAudio]){
        [[SimpleAudioEngine sharedEngine]playEffect:@"lose.mp3"];
    }
    
    if (IS_IPHONE_5) {
        [self setBgWithFileName:@"bg-568h@2x.jpg"];
    }else{
        [self setBgWithFileName:SD_OR_HD(@"bg.jpg")];
    }
    
    //分数
    CCLabelBMFont* loseLabel = [CCLabelBMFont labelWithString:@"OH-NO!\n You Lose!" fntFile:@"futura-48.fnt"];
    loseLabel.position=ccp(winSize.width/2, winSize.height*2/3);
    loseLabel.scale=HD2SD_SCALE;
    [self addChild:loseLabel];
    
    //操作菜单
    CCMenu* menuButton= [SpriteUtil createMenuWithFrame:@"button_menu.png" pressedColor:ccYELLOW target:self selector:@selector(menu)];
    menuButton.position=ccp(winSize.width/2-(IS_IPAD()?150:70), winSize.height*1/3);
    [self addChild:menuButton z:zAboveOperation];
    
    CCMenu* restartButton= [SpriteUtil createMenuWithFrame:@"button_refresh.png" pressedColor:ccYELLOW target:self selector:@selector(restart)];
    restartButton.position=ccp(winSize.width/2+(IS_IPAD()?150:70), winSize.height*1/3);
    [self addChild:restartButton z:zAboveOperation];

    return self;
}

-(void) menu
{
	CCScene *sc = [CCScene node];
	[sc addChild:[MenuLayer node]];
	[[CCDirector sharedDirector] replaceScene:  [CCTransitionSplitRows transitionWithDuration:1.0f scene:sc]];
}
-(void) restart
{
	CCScene *sc =[GameLayer scene];
    [[CCDirector sharedDirector] replaceScene: [CCTransitionSplitRows transitionWithDuration:1.0f scene:sc]];
}


@end
