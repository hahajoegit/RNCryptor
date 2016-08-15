//
//  ObjC.m
//
//  Copyright © 2015 Rob Napier. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
@import RNCryptor;
#import <CommonCrypto/CommonCryptor.h>

@interface ObjC : XCTestCase

@end

@implementation ObjC

// FIXME: ObjC unavailable pending https://openradar.appspot.com/radar?id=4974177417166848

NSData *randomDataOfLength(NSInteger length) {
    NSMutableData *data = [[NSMutableData alloc] initWithLength:length];
    int result = SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    NSCAssert(result == errSecSuccess, @"SecRandomCopyBytes must succeed");
    return data;
}

- (void)testOneShotKey {
    NSData *encryptionKey = randomDataOfLength(kCCKeySizeAES256);
    NSData *hmacKey = randomDataOfLength(kCCKeySizeAES256);
    NSData *data = randomDataOfLength(1024);

    NSData *ciphertext = [[[RNEncryptorV3 alloc] initWithEncryptionKey:encryptionKey hmacKey:hmacKey] encryptWithData:data];
    XCTAssertNotNil(ciphertext);

    NSError *error = nil;
    NSData *plaintext = [[[RNDecryptorV3 alloc] initWithEncryptionKey:encryptionKey hmacKey:hmacKey] decryptWithData:ciphertext error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(plaintext, data);
}

- (void)testOneShotPassword {
    NSString *password = @"PASSWORD";
    NSData *data = randomDataOfLength(1024);

    NSData *ciphertext = [[[RNEncryptor alloc] initWithPassword:password] encryptWithData:data];
    XCTAssertNotNil(ciphertext);

    NSError *error = nil;
    NSData *plaintext = [[[RNDecryptor alloc] initWithPassword:password] decryptWithData:ciphertext error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(plaintext, data);
}

- (void)testOneShotPasswordV3 {
    NSString *password = @"PASSWORD";
    NSData *data = randomDataOfLength(1024);

    NSData *ciphertext = [[[RNEncryptorV3 alloc] initWithPassword:password] encryptWithData:data];
    XCTAssertNotNil(ciphertext);

    NSError *error = nil;
    NSData *plaintext = [[[RNDecryptorV3 alloc] initWithPassword:password] decryptWithData:ciphertext error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(plaintext, data);
}

- (void)testUpdatesPassword {
    NSString *password = @"PASSWORD";
    NSData *data = randomDataOfLength(1024);

    RNEncryptor *cryptor = [[RNEncryptor alloc] initWithPassword:password];
    XCTAssertNotNil(cryptor);

    NSMutableData *ciphertext = [NSMutableData new];
    [ciphertext appendData:[cryptor updateWithData:data]];
    [ciphertext appendData:[cryptor finalData]];
    XCTAssertGreaterThan(ciphertext.length, data.length);


    NSError *error = nil;
    RNDecryptor *decryptor = [[RNDecryptor alloc] initWithPassword:password];
    XCTAssertNotNil(decryptor);

    NSMutableData *plaintext = [NSMutableData new];
    [plaintext appendData:[decryptor updateWithData:ciphertext error:&error]];
    XCTAssertNil(error);
    [plaintext appendData:[decryptor finalDataAndReturnError:&error]];
    XCTAssertNil(error);

    XCTAssertEqualObjects(plaintext, data);
}

- (void)testBadFormat {
    NSData *data = [[NSMutableData alloc] initWithLength:1024];
    NSString *password = @"PASSWORD";

    NSError *error = nil;
    NSData *plaintext = [RNCryptor decryptWithData:data withPassword:password error:&error];
    XCTAssertNil(plaintext);
    XCTAssertEqual(error.code, RNCryptorErrorUnknownHeader);
}

- (void)testClass {
    NSString *password = @"PASSWORD";
    NSData *data = randomDataOfLength(1024);

    NSData *ciphertext = [RNCryptor encryptWithData:data withPassword:password];
    XCTAssertNotNil(ciphertext);

    NSError *error = nil;
    NSData *plaintext = [RNCryptor decryptWithData:ciphertext withPassword:password error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(plaintext, data);
}

@end
