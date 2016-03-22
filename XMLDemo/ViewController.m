//
//  ViewController.m
//  XMLDemo
//
//  Created by 千锋 on 16/3/22.
//  Copyright © 2016年 mobiletrain. All rights reserved.
//

#import "ViewController.h"
#import "NewsDetailModel.h"
#import <Ono.h>


@interface ViewController ()<NSXMLParserDelegate>

@property (nonatomic,strong)NSXMLParser *parser; //SAX

@property (nonatomic,strong)NewsDetailModel *detailModel; //数据模型

@property (nonatomic,copy)NSString * nodeName;//记录当前解析的节点名称
@property (nonatomic,copy)ONOXMLDocument *onoDoc;//DOM解析方式
@property (weak, nonatomic) IBOutlet UILabel *titleLable;

@property (weak, nonatomic) IBOutlet UIWebView *webView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self SAXDemo];
    
    [self DOMDemo];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -DOM
-(void)DOMDemo{
    
    __weak typeof(self) weakSelf=self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSData *xmlData=[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.oschina.net/action/api/news_detail?id=44393"]];
        NSLog(@"%@",xmlData);
        
        NSError *error;
        //创建ono dom解析文档对象
        weakSelf.onoDoc=[ONOXMLDocument XMLDocumentWithData:xmlData error:&error];
        //获取dom的根节点
        ONOXMLElement *rootElement=weakSelf.onoDoc.rootElement;
        NSLog(@"rootElement=%@",rootElement.tag);
        
        ONOXMLElement * idElement=[rootElement firstChildWithXPath:@"//news/id"];
        NSLog(@"idElement= %@",idElement.tag);
        
        //若要找到多个相同节点  需要找到节点的父节点 再通过父节点获取所有的子节点
        ONOXMLElement *relativesElement=[rootElement firstChildWithXPath:@"//news/relatives"];
        
        
        NSArray *relatives=[relativesElement childrenWithTag:@"relative"];
        
        //找到news节点
        ONOXMLElement *newsElement=[rootElement firstChildWithTag:@"news"];
        //找到title节点
        ONOXMLElement *titleElement=[newsElement firstChildWithTag:@"title"];
        
        //获取title节点前一个节点
        ONOXMLElement *preTitleElement=titleElement.previousSibling;
        
        //获取title节点后一个节点
        
        ONOXMLElement *nextTitleElement=titleElement.nextSibling;
        //创建模型 找到相应的节点数据
        weakSelf.detailModel=[[NewsDetailModel alloc]init];
       weakSelf.detailModel.ID=[idElement stringValue];
        weakSelf.detailModel.title=[titleElement stringValue];
        //找到body节点
        ONOXMLElement *bodyElement=[newsElement firstChildWithTag:@"body"];
        weakSelf.detailModel.body=bodyElement.stringValue;
        
        NSLog(@"model id=%@,title =%@ body=%@",weakSelf.detailModel.ID,weakSelf.detailModel.title,weakSelf.detailModel.body);
        
        //回到主队列加载数据到UI上
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.titleLable.text=weakSelf.detailModel.title;
            
            //UIWebView 第一种加载网页  加载已有的html代码
            [weakSelf.webView loadHTMLString:weakSelf.detailModel.body baseURL:nil];
            
            
            
        });
        
        
    });
    
}









//SAX XML解析方式
-(void)SAXDemo{
    
    __weak typeof(self) weakSelf=self;
    //typeof( -- ) 动态类型
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *datatask=[session dataTaskWithURL:[NSURL URLWithString:@"http://www.oschina.net/action/api/news_detail?id=44393"]   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"%@",data);
        NSString *mstr=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",mstr);
        
        //创建NSXMLParser对象
        weakSelf.parser=[[NSXMLParser alloc]initWithData:data];
        
        //设置代理 委托
        weakSelf.parser.delegate=weakSelf;
        //开始解析
        [weakSelf.parser parse];
        
        //中断/结束解析
//        [weakSelf.parser abortParsing];
        
        
        
    }];
    [datatask resume];
    
    
}

#pragma mark -NSXMLParserDelegate

//开始解析XML文档
-(void)parserDidStartDocument:(NSXMLParser *)parser{
    
    //在该协议方法实现中 创建数据模型
    
    self.detailModel=[[NewsDetailModel alloc]init];
    
    NSLog(@"XML文档解析开始");
    
}

//结束解析
-(void)parserDidEndDocument:(NSXMLParser *)parser{
    
    
    NSLog(@"XML文档解析结束");
    
    NSLog(@"NewsDetailModel %@ %@",self.detailModel.ID,self.detailModel.title);
    
}
/**
 *  解析节点数据相关方法
 */
//
/**
 *  开始解析XML节点元素
 *
 *  @param parser        NSXMLParser 解析类
 *  @param elementName   节点名称
 *  @param namespaceURI  命名空间URI    URL 是URI的子集
 *  @param qName         命名空间中的描述名称
 *  @param attributeDict 属性字典  属性的名称（value）和值
 */
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict{
    
    NSLog(@"elementName= %@ attributeDict= %@",elementName,attributeDict);
    //记录当前正在解析的节点
    self.nodeName=elementName;
    
}


-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    NSLog(@"某个XML节点 %@ 元素解析结束",elementName);
    
}

/**
 *  解析XML节点中的文本信息
 */
//解析节点中CDATA的数据
-(void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock{
    
    
   NSString *cdataStr=[[NSString alloc]initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    NSLog(@"%@",cdataStr);
    
    //为数据模型赋值
    
    if ([self.nodeName isEqualToString:@"title"]) {
        self.detailModel.title=cdataStr;
    }
}
//解析节点中普通字符数据
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    
    NSLog(@"foundchara %@",string);
    if ([self.nodeName isEqualToString:@"id"]) {
        self.detailModel.ID=string;
    }
}




@end
