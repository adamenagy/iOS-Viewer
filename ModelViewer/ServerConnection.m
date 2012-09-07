//
//  ServerConnection.m
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import "ServerConnection.h"

#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <AWSiOSSDK/S3/S3ListObjectsRequest.h>
#import <AWSiOSSDK/S3/S3GetObjectRequest.h>

#pragma mark - Point3d

@implementation Point3d
- (Point3d *)initWith:(double)xVal y:(double)yVal z:(double)zVal
{
    self.x = xVal;
    self.y = yVal;
    self.z = zVal;
    
    return self;
}

@synthesize x;
@synthesize y;
@synthesize z;

@end

#pragma mark - FacetData

@implementation FacetData
@synthesize pts = _pts;
@synthesize normals = _normals;
@end

#pragma mark - FaceData

@implementation FaceData
@synthesize facets = _facets;
@synthesize red = _red;
@synthesize green = _green;
@synthesize blue = _blue;
@end

#pragma mark - ServerConnection

@implementation ServerConnection

+(void)showAlert:(NSString *)message withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

+ (NSMutableArray *)getItemNames
{
    AmazonS3Client * s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    
    NSMutableArray * names = [[NSMutableArray alloc] init];
    
    @try 
    {
        S3ListObjectsRequest * listObjectsRequest = [[S3ListObjectsRequest alloc] initWithName:PICTURE_BUCKET];  
        
        S3ListObjectsResponse * response = [s3 listObjects:listObjectsRequest];
        
        NSMutableArray * objectSummaries = response.listObjectsResult.objectSummaries; 
        for (S3ObjectSummary * summary in objectSummaries)
        {
            [names addObject:[summary key]];
        }
    }
    @catch (AmazonClientException * exception) 
    {
        [self showAlert:exception.message withTitle:@"Download Error"];
    }
    
    return names;
}

+ (NSMutableArray *)getFacets:(NSString *)withName
{
    @try 
    {
        AmazonS3Client * s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
        
        S3GetObjectRequest * request = [[S3GetObjectRequest alloc] initWithKey:withName withBucket:PICTURE_BUCKET];   
        
        S3GetObjectResponse * response = [s3 getObject:request];
        
        NSData * data = [response body];
        
        // Convert it to list of points
        return [self getFacetsFromData:data];
    }
    @catch (AmazonClientException * exception) 
    {
        [self showAlert:exception.message withTitle:@"Download Error"];
    }
    
    return [[NSMutableArray alloc] init];
}

+ (NSMutableArray *)getPoints:(NSString *)fromString
{
    NSMutableArray * points = [[NSMutableArray alloc] init];
    
    NSArray * pts = [fromString componentsSeparatedByString:@";"]; 
    for (NSString * pt in pts)
    {
        NSArray * vertices = [pt componentsSeparatedByString:@", "];
        NSString * x = [vertices objectAtIndex:0];
        NSString * y = [vertices objectAtIndex:1];
        NSString * z = [vertices objectAtIndex:2];
        
        Point3d * pt = [[Point3d alloc] initWith:[x doubleValue] y:[y doubleValue] z:[z doubleValue]];
        
        [points addObject:pt];
    }
    
    return points;
}

+ (NSMutableArray *)getFacetsFromData:(NSData *)data
{
    NSString * str = 
    [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray * faces = [[NSMutableArray alloc] init];
    
    NSArray * lines = [str componentsSeparatedByString:@"\n"];
    
    FaceData * face = nil;
    NSMutableArray * facets = nil;
    for (NSString * line in lines)
    {
        if (line.length < 1)
            continue;
        
        if ([line characterAtIndex:0] == 'c')
        {
            // Create face
            face = [FaceData alloc];

            // Get color to use
            NSArray * colors = [line componentsSeparatedByString:@"="];
            NSArray * values = [[colors objectAtIndex:1] componentsSeparatedByString:@", "];
            face.red = [[values objectAtIndex:0] intValue];
            face.green = [[values objectAtIndex:1] intValue];
            face.blue = [[values objectAtIndex:2] intValue];
    
            // Create facet list of face
            facets = [[NSMutableArray alloc] init];
            face.facets = facets;
            [faces addObject:face];
        }
        else 
        {
            FacetData * facet = [FacetData alloc];
            
            NSArray * parts = [line componentsSeparatedByString:@"|"];
            
            facet.pts = [ServerConnection getPoints:[parts objectAtIndex:0]];
            facet.normals = [ServerConnection getPoints:[parts objectAtIndex:1]];
            
            [facets addObject:facet];
        }
    }
    
    return faces; 
}

@end
