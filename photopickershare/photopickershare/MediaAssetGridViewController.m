

#import "MediaAssetGridViewController.h"

#import "MediaGridViewCell.h"
#import "MediaAssetViewController.h"



@import Photos;


@implementation NSIndexSet (Convenience)
- (NSArray *)aapl_indexPathsFromIndexesWithSection:(NSUInteger)section {
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
	[self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
	}];
	return indexPaths;
}
@end


@implementation UICollectionView (Convenience)
- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
	NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
	if (allLayoutAttributes.count == 0) { return nil; }
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
	for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
		NSIndexPath *indexPath = layoutAttributes.indexPath;
		[indexPaths addObject:indexPath];
	}
	return indexPaths;
}
@end


@interface MediaAssetGridViewController () <PHPhotoLibraryChangeObserver>
@property (strong) IBOutlet UIBarButtonItem *addButton;
@property (strong) PHCachingImageManager *imageManager;
@property CGRect previousPreheatRect;
@end


@implementation MediaAssetGridViewController

static NSString * const CellReuseIdentifier = @"Cell";
static CGSize AssetGridThumbnailSize;


- (id) initWithIndexPath: (NSIndexPath*)indexPath {
    
    // Call superclass's initializer
    self = [super init];
    if( !self ) return nil;
    
    

    
   // NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
//    MediaAssetViewController *assetViewController = segue.destinationViewController;
//    assetViewController.asset = self.assetsFetchResults[indexPath.item];
//    assetViewController.assetCollection = self.assetCollection;
    
    return self;
}

#define kCellsPerRow 3

-(void)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{ NSLog(@"controller dismissed"); }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
     [self.navigationItem setTitle:@"FaceSwapper"];
  
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(close:)];
    
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    
    // Configure layout
    //[layout setItemSize:CGSizeMake(191, 160)];
    [layout setScrollDirection:UICollectionViewScrollDirectionVertical];
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.minimumInteritemSpacing = 10.0f;
    layout.minimumLineSpacing = 10.0f;

    CGFloat availableWidthForCells = self.view.frame.size.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing * (kCellsPerRow - 1);
    CGFloat cellWidth = availableWidthForCells / kCellsPerRow;
    layout.itemSize = CGSizeMake(cellWidth, cellWidth);
    
    _collectionView=[[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    _collectionView.bounces = YES;
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    
    
    
    [_collectionView registerClass:[MediaGridViewCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
    //[_collectionView setBackgroundColor:[UIColor redColor]];
    
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = ((UICollectionViewFlowLayout *)layout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    
//    if (!self.assetCollection || [self.assetCollection canPerformEditOperation:PHCollectionEditOperationAddContent]) {
//        self.navigationItem.rightBarButtonItem = self.addButton;
//    } else {
//        self.navigationItem.rightBarButtonItem = nil;
//    }
    
    
    
    [self.view addSubview:_collectionView];
    

    
    self.imageManager = [[PHCachingImageManager alloc] init];
    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    

}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//    
//    //return CGSizeMake(50, 50);
//}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCachedAssets];
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
//    MediaAssetViewController *assetViewController = segue.destinationViewController;
//    assetViewController.asset = self.assetsFetchResults[indexPath.item];
//    assetViewController.assetCollection = self.assetCollection;
//}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"select path");
    
    MediaAssetViewController *assetViewController = [[MediaAssetViewController alloc] init];
    assetViewController.asset = self.assetsFetchResults[indexPath.item];
    assetViewController.assetCollection = self.assetCollection;
    
    
    [[self navigationController] pushViewController:assetViewController animated:YES];

    
}




#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // check if there are changes to the assets (insertions, deletions, updates)
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
        if (collectionChanges) {
            
            // get the new fetch result
            self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
            
            UICollectionView *collectionView = _collectionView;
            
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // we need to reload all if the incremental diffs are not available
                [collectionView reloadData];
                
            } else {
                // if we have incremental diffs, tell the collection view to animate insertions and deletions
                [collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                } completion:NULL];
            }
            
            [self resetCachedAssets];
        }
    });
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.assetsFetchResults.count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MediaGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    [self.imageManager requestImageForAsset:asset
								 targetSize:AssetGridThumbnailSize
								contentMode:PHImageContentModeAspectFill
									options:nil
							  resultHandler:^(UIImage *result, NSDictionary *info) {
        
        // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
        if (cell.tag == currentTag) {
            
            //cell.backgroundColor = [UIColor blueColor];
            //[(MediaGridViewCell*)cell setThumbnailImage:result];
            cell.thumbnailImage = result;
            
            if (asset.mediaType == PHAssetMediaTypeVideo) {
                [cell setMediaType:MediaFileTypeVideo withDuration:asset.duration];
             }
            
            if( [[[[asset valueForKey:@"filename"] pathExtension] lowercaseString] isEqualToString:@"gif"]) {
                [cell setMediaType:MediaFileTypeGif withDuration:asset.duration];
   
            }

            
            
            
            //NSLog(@"restult: %@",result);
        }
        
    }];
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = _collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(_collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [_collectionView aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [_collectionView aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
											targetSize:AssetGridThumbnailSize
										   contentMode:PHImageContentModeAspectFill
											   options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
										   targetSize:AssetGridThumbnailSize
										  contentMode:PHImageContentModeAspectFill
											  options:nil];

         self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assets addObject:asset];
    }
    return assets;
}

#pragma mark - Actions

- (IBAction)handleAddButtonItem:(id)sender
{
    // Create a random dummy image.
    CGRect rect = rand() % 2 == 0 ? CGRectMake(0, 0, 400, 300) : CGRectMake(0, 0, 300, 400);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0f);
    [[UIColor colorWithHue:(float)(rand() % 100) / 100 saturation:1.0 brightness:1.0 alpha:1.0] setFill];
    UIRectFillUsingBlendMode(rect, kCGBlendModeNormal);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Add it to the photo library
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        if (self.assetCollection) {
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.assetCollection];
            [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error creating asset: %@", error);
        }
    }];
}

@end


