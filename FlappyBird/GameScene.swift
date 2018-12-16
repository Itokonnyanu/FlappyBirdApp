//
//  GameScene.swift
//  FlappyBird
//
//  Created by 佐々木　祐太 on 2018/12/15.
//  Copyright © 2018 佐々木　祐太. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode :SKNode!
    var bird: SKSpriteNode!
    var wallNode: SKNode!
    var sprite: SKSpriteNode!
    var wall: SKNode!
    var candy: SKSpriteNode!
    // 衝突判定カテゴリー(識別子)
    
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let candyCategory: UInt32 = 1 << 4
    
    // スコア
    var score = 0
    var itemScore = 0
    let userDefaults:UserDefaults = UserDefaults.standard
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    
    var audioPlayerInstance: AVAudioPlayer!
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        // シーンにスクロールノードを追加
        addChild(scrollNode)
        
        let soundFilePath = Bundle.main.path(forResource: "se_maoudamashii_retro07", ofType: "mp3")!
        let sound:URL = URL(fileURLWithPath: soundFilePath)
        // AVAudioPlayerのインスタンスを作成
        do {
            audioPlayerInstance = try AVAudioPlayer(contentsOf: sound, fileTypeHint:nil)
        } catch {
            print("AVAudioPlayerインスタンス作成失敗")
        }
        // バッファに保持していつでも再生できるようにする
        audioPlayerInstance.prepareToPlay()
        
        setupGroud()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
    }
    
    //画面タッチ時の処理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            //gameover時
        }else if bird.speed == 0{
            restart()
        }
    }
    func setupGroud (){
        
        // 地面の画像からスプライトの前身であるテクスチャを作る
        let groundTexture = SKTexture(imageNamed: "ground")
        // 画像縮尺時の編集
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5.0)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        //繰り返し
        for i in 0..<needNumber {
            //groundのテクスチャからスプライトの作成
            sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width * (CGFloat(i) + 0.5),
                y: groundTexture.size().height * 0.5
            )
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            // 動かないように設定する
            sprite.physicsBody?.isDynamic = false
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            // シーンにスプライトノードを追加する
            scrollNode.addChild(sprite)
        }
        
    }
    
    func setupCloud(){
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20.0)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
                y: self.size.height - cloudTexture.size().height * 0.5
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    
    func setupWall() {
        
        // 壁用のノード
        wallNode = SKNode()
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -2*movingDistance, y: 0, duration:8.0)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            self.wall = SKNode()
            //右画面の向こう側に設置
            self.wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            self.wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            // 壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            // 下の壁のY軸の下限
            //arc4random_uniformの返り値の型であるUInt32型にキャスティング
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 6
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //カテゴリーをwallcategoryに設定
            under.physicsBody?.categoryBitMask = self.wallCategory
            // 動かないように設定する
            under.physicsBody?.isDynamic = false
            //wallノードに追加
            self.wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            //スプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //カテゴリーをwallcategoryに設定
            upper.physicsBody?.categoryBitMask = self.wallCategory
            // 動かないように設定する
            upper.physicsBody?.isDynamic = false
            //wallノードに追加
            self.wall.addChild(upper)
            
    //キャンディの設定
            //テクスチャの設定
            let candyTexture = SKTexture(imageNamed: "candy")
            candyTexture.filteringMode = .linear
            //キャンディのスプライトノード設定
            let candy = SKSpriteNode(texture: candyTexture)
        
            //キャンディを置くときのx座標の余白
            let margin = upper.size.width*1.5 + self.bird.size.width/2 + candy.size.width/2
            //キャンディをランダムで配置するときの最大値
            let random_x_rangeCandy = self.frame.size.width - margin
            //１〜random_x_range2までのランダムな整数を生成
            let random_x_Candy = arc4random_uniform(UInt32(random_x_rangeCandy))
            //ランダムな値に余白を足して、キャンディのx座標を決定
            let candy_x = margin + CGFloat(random_x_Candy)
            
            //キャンディを置くときのy座標をランダムで決定
            let random_y_rangeCandy = self.frame.size.height - self.sprite.size.height - candy.size.height
            let random_y_Candy = arc4random_uniform(UInt32(random_y_rangeCandy))
            let candy_y = self.sprite.size.height + candy.size.height/2 + CGFloat(random_y_Candy)
            candy.position = CGPoint(x: candy_x, y: candy_y)
            //物理演算を設定
            candy.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: candy.size.width, height: candy.size.height))
            //動かない
            candy.physicsBody?.isDynamic = false
            //カテゴリーをcandyCategoryに設定
            candy.physicsBody?.categoryBitMask = self.candyCategory
           
            self.wall.addChild(candy)
            
    //スコアアップ壁の設定
            // スコアアップ壁のノード
            let scoreNode = SKNode()
            //壁を完全に抜けきったところにスコアアップ壁設定
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            //物理演算を設定
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            //動かない
            scoreNode.physicsBody?.isDynamic = false
            //カテゴリーをscoreCategoryに設定
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
           
            self.wall.addChild(scoreNode)
            
            self.wall.run(wallAnimation)
            //wallNodeノードに追加
            self.wallNode.addChild(self.wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 4)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
        //スクロールノードに追加
        scrollNode.addChild(wallNode)
    }
    
    
    func setupBird() {
        
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)    // ←追加
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // カテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        //衝突する対象を限定、これ以外は貫通
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        //接触判定する相手を設定
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory | candyCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトをシーンに追加する
        addChild(bird)
    }
    // SKPhysicsContactDelegateのメソッド。接触したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        // スコア用の壁と接触した
        if contact.bodyA.categoryBitMask == scoreCategory || contact.bodyB.categoryBitMask == scoreCategory {
            
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                //この時はまだ保留中
                userDefaults.set(bestScore, forKey: "BEST")
                //保留中の保存を即座に実行する。
                userDefaults.synchronize()
            }
        //candyと接触した
        } else if contact.bodyA.categoryBitMask == candyCategory || contact.bodyB.categoryBitMask == candyCategory{
            // candyを取り除く
            if contact.bodyA.categoryBitMask == candyCategory{
            contact.bodyA.node?.removeFromParent()
            }else{
                contact.bodyB.node?.removeFromParent()
            }
            audioPlayerInstance.play()
            print("ItemGet")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
        }else {
            // 壁か地面と接触した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            //衝突する対象をgroundCategoryに限定
            bird.physicsBody?.collisionBitMask = groundCategory
            //gameover時に鳥が回転する
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            //birdのアクションスピードを0に
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    //ゲームリスタート
    func restart() {
        score = 0
        itemScore = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemScoreLabelNode.text = String("Item Score:\(itemScore)")
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel(){
        
        //現在のscoreのノード
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        // 一番手前に表示する
        scoreLabelNode.zPosition = 100
        //文字左詰のラベル
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        //シーンに追加
        self.addChild(scoreLabelNode)
        
        //itemScoreのノード
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        // 一番手前に表示する
        itemScoreLabelNode.zPosition = 100
        //文字左詰のラベル
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        //シーンに追加
        self.addChild(itemScoreLabelNode)
        
        //bestscoreのノード
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        // 一番手前に表示する
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        //シーンに追加
        self.addChild(bestScoreLabelNode)
    }
}
















