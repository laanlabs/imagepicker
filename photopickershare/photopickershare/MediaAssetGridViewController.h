

@import UIKit;
@import Photos;



//@interface MediaAssetGridViewController : UIViewController

@interface MediaAssetGridViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    UICollectionView *_collectionView;
}

@property (strong) PHFetchResult *assetsFetchResults;
@property (strong) PHAssetCollection *assetCollection;

@end
