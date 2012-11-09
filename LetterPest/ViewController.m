//
//  ViewController.m
//  LetterPest
//
//  Created by Mick Thompson on 11/8/12.
//  Copyright (c) 2012 Mick Thompson. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AFNetworking/AFNetworking.h>
#import <UIKit/UIKit.h>

@interface ViewController ()

- (void)uploadBoardwithImage:(UIImage*)image;
- (void)updateWebView:(AFHTTPRequestOperation*)operation;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        // Chooses the photo at the last index
        NSInteger totalImages = [group numberOfAssets];
        [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex: (totalImages-1) ]  options:0 usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            
            // The end of the enumeration is signaled by asset == nil.
            if (alAsset) {
                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage] scale:4.0 orientation:UIImageOrientationUp];

                // Do something interesting with the AV asset.

                UIImageView *theboard = [[UIImageView alloc ] initWithImage:latestPhoto];

                [self.view addSubview:theboard];
                [self uploadBoardwithImage:latestPhoto];
            }
        }];
    } failureBlock: ^(NSError *error) {
        // Typically you should handle an error more gracefully than this.
        NSLog(@"No groups");
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)uploadBoardwithImage:(UIImage*)image
{
    NSData* imageData = UIImageJPEGRepresentation(image, 60.0); 
    
    NSDictionary *sendDictionary = [NSDictionary dictionary];
    NSURL *remoteUrl = [NSURL URLWithString:@"http://letterpest.herokuapp.com"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:remoteUrl];
    NSMutableURLRequest *afRequest = [httpClient multipartFormRequestWithMethod:@"POST"
                                                                           path:@"/file-upload"
                                                                     parameters:sendDictionary
                                                      constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
                                      {
                                          [formData appendPartWithFileData:imageData
                                                                      name:@"image_name"
                                                                  fileName:@"letterpest.jpg"
                                                                  mimeType:@"image/jpeg"];
                                      }
                                      ];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:afRequest];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long  totalBytesWritten, long long  totalBytesExpectedToWrite) {
        
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        
    }];
    __block id weakOperation = operation;
    [operation setCompletionBlock:^{
        NSLog(@"response: %@", operation.responseString); //Gives a very scary warning

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateWebView:weakOperation];
        });
    }];
    
    [operation start];
    

}
- (void)updateWebView:(AFHTTPRequestOperation*)operation{

    UIWebView *webview = [[UIWebView alloc ] initWithFrame:self.view.frame];
    [webview loadHTMLString:operation.responseString baseURL:operation.request.URL];
    [self.view addSubview:webview];
}



@end
