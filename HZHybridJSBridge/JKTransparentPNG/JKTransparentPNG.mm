//
//  JKTransparentPNG.m
//  app
//
//  Created by huangbenhua on 16/3/27.
//  Copyright © 2016年 hdaren. All rights reserved.
//

#import "JKTransparentPNG.h"
#import "NSMassKit.h"

#define byte8 unsigned char

@interface JKTransparentPNG()
{
     int width, height,depth;
     int pix_size,data_size;
     int ihdr_offs,ihdr_size,plte_offs,plte_size;
     int trns_offs,trns_size;
     int idat_offs,idat_size;
     int iend_offs,iend_size,buffer_size;
     byte8* buffer;
     int offs;
}

-(void)buildWithSize:(CGSize)size;

-(NSString*)getBase64Text:(CGSize)size;

@end



@implementation JKTransparentPNG


-(NSString*)getBase64Text:(CGSize)size
{
    [self buildWithSize:size];
    [self flush];
    return [[self getData] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
};

+(NSString*)Base64Text:(CGSize)size
{
    static NSMutableDictionary* base64texts = 0;
    if (base64texts == 0) {
        base64texts = [NSMutableDictionary dictionary];
    }
    int width = size.width,height=size.height;
    if(width < 1 || height < 1)return @"";
    if(width > 17 || width < height){
        return [[[JKTransparentPNG alloc] init] getBase64Text:size];
    }
    NSString* key = [NSString stringWithFormat:@"%@_%@", @(width), @(height)];
    NSString* txt = [base64texts stringForKey:key];
    if(txt&&txt.length > 0){
        return txt;
    }
    txt = [[[JKTransparentPNG alloc] init] getBase64Text:size];
    [base64texts setObject:txt forKey:key];
    return txt;
};

-(NSData*)getData
{
    if (buffer == 0) {
        return nil;
    }
    return [NSData dataWithBytesNoCopy:buffer length:buffer_size freeWhenDone:NO];
}

-(void)_byte:(byte8)b{
    buffer[offs++] = b;
}

-(void)_str:(NSString*)str{
    for(int i = 0; i < str.length; i ++){
        buffer[offs++] = (byte8)[str characterAtIndex:i];
    }
}

-(void)_short:(int)w{
    buffer[offs++] = (byte8)((w >> 8) & 255);
    buffer[offs++] = (byte8)(w & 255);
}


-(void)_int:(int)w{
    buffer[offs++] = (byte8)((w >> 24) & 255);
    buffer[offs++] = (byte8)((w >> 16) & 255);
    buffer[offs++] = (byte8)((w >> 8) & 255);
    buffer[offs++] = (byte8)(w & 255);
}

-(void)_lsb:(int)w{
    buffer[offs++] = (byte8)(w & 255);
    buffer[offs++] = (byte8)((w >> 8) & 255);
}

-(void)crc32:(int)voffs size:(int)size{
    static int* _crc32 = 0;
    if (_crc32 == 0) {
        _crc32 = (int *)malloc(256 * sizeof(int));
        for (int i = 0; i < 256; i++) {
            int c = i;
            for (int j = 0; j < 8; j++) {
                if ((c & 1) > 0) {
                    c = -306674912 ^ ((c >> 1) & 0x7fffffff);
                } else {
                    c = (c >> 1) & 0x7fffffff;
                }
            }
            _crc32[i] = c;
        }
    }
    int crc = -1;
    for (int i = 4; i < size-4; i += 1) {
        crc = _crc32[(crc ^ buffer[voffs+i]) & 0xff] ^ ((crc >> 8) & 0x00ffffff);
    }
    offs = voffs+size-4;
    [self _int:crc ^ -1];
}

-(void)buildWithSize:(CGSize)size
{
    offs = 0;
    depth = 2;
    width = size.width;
    height= size.height;
    buffer = 0;
    
    // pixel data and row filter identifier size
    pix_size = height * (width + 1);
    
    // deflate header, pix_size, block headers, adler32 checksum
    data_size = 2 + pix_size + 5 * (int)floor((0xfffe + pix_size) / 0xffff) + 4;
    
    // offsets and sizes of Png chunks
    ihdr_offs = 8;									// IHDR offset and size
    ihdr_size = 4 + 4 + 13 + 4;
    plte_offs = ihdr_offs + ihdr_size;	// PLTE offset and size
    plte_size = 4 + 4 + 3 * depth + 4;
    trns_offs = plte_offs + plte_size;	// tRNS offset and size
    trns_size = 4 + 4 + depth + 4;
    idat_offs = trns_offs + trns_size;	// IDAT offset and size
    idat_size = 4 + 4 + data_size + 4;
    iend_offs = idat_offs + idat_size;	// IEND offset and size
    iend_size = 4 + 4 + 4;
    buffer_size  = iend_offs + iend_size;	// total TransparentPNG size
    
    //
    buffer = (byte8 *)malloc(buffer_size);
    
    [self _int:0x89504e47];
    [self _int:0x0d0a1a0a];
    
    // initialize non-zero elements
    offs = ihdr_offs;
    [self _int:ihdr_size - 12];
    [self _str:@"IHDR"];
    [self _int:width];
    [self _int:height];
    [self _short:0x0803];
    
    offs = plte_offs;
    [self _int:plte_size - 12];
    [self _str:@"PLTE"];
    //[self _int:0xcccc0000);//缺省填一个颜色
    //
    offs = trns_offs;
    [self _int:trns_size - 12];
    [self _str:@"tRNS"];
    
    offs = idat_offs;
    [self _int:idat_size - 12];
    [self _str:@"IDAT"];
    
    offs = iend_offs;
    [self _int:iend_size - 12];
    [self _str:@"IEND"];
    [self _int:0xae426082];
    
    // initialize deflate header
    int header = ((8 + (7 << 4)) << 8) | (3 << 6);
    header+= 31 - (header % 31);
    
    offs = idat_offs + 8;
    [self _short:header];
    
    // initialize deflate block headers
    for (int i = 0; (i << 16) - 1 < pix_size; i++) {
        int size; byte8 bits;
        if (i + 0xffff < pix_size) {
            size = 0xffff;
            bits = 0;
        } else {
            size = pix_size - (i << 16) - i;
            bits = 1;
        }
        offs = idat_offs + 8 + 2 + (i << 16) + (i << 2);
        [self _byte:bits];
        [self _lsb:size];
        [self _lsb:~size];
    }
}

-(void)flush{
    
    //因为是纯色,所以所有数值都是0,因此代码写入的是一个能经过简单计算得到的数值
    int s1 = 1,s2=width * 10 + height;
    offs = idat_offs + idat_size - 8;
    [self _int:((s2 << 16) | s1)];
    
    // compute crc32 of the TransparentPNG chunks
    [self crc32:ihdr_offs size:ihdr_size];
    [self crc32:plte_offs size:plte_size];
    [self crc32:trns_offs size:trns_size];
    [self crc32:idat_offs size:idat_size];
    //crc32(this.iend_offs, this.iend_size);
    
}
-(void)dealloc
{
    if (buffer != 0) {
        free(buffer);
        buffer = 0;
    }
}

@end
