
@interface GameLayer : MyBaseLayer

@property (nonatomic,assign) CCTMXTiledMap * gameWorld;
@property (nonatomic,readwrite,assign) float mapX;
@property (nonatomic,readwrite,assign) float mapY;
@property (nonatomic,readwrite,assign) float screenWidth;
@property (nonatomic,readwrite,assign) float screenHeight;
@property (nonatomic,readwrite,assign) float tileSize;

@property (nonatomic,readwrite,assign) BOOL gameSuspended;
@property (nonatomic,readwrite,assign) int score;
//碰到spike减1，为0时候游戏结束
@property (nonatomic,readwrite,assign) int life;
@property (retain,nonatomic) CCLayer* pauseLayer;
@property BOOL isTrickWorking; //tric coin是否工作


- (void)step:(ccTime)dt;
-(void)initSpriteSheet;
- (void) setWorldPosition;

-(float) gameWorldWidth;
-(float) gameWorldHeight;
-(unsigned int)tileIDFromPosition:(CGPoint)pos withLayer:(NSString*) layerName;

-(CGPoint)tileCoordinateFromPos:(CGPoint)pos;

- (void)startGame;

- (void)resetBird;

- (void)step:(ccTime)dt;
- (void)gameOverWin:(BOOL)win ;
@end
