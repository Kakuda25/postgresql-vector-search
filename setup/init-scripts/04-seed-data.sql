-- ============================================
-- 初期データ（シードデータ）
-- ============================================
-- 歯科医院向けのサンプルデータ
-- ON CONFLICT句により、既存データがある場合はスキップされる
INSERT INTO products (product_code, name, description, price, status, image_url, weight_kg, dimensions) VALUES
('EQUIP-001', 'ハンドピース 標準型', '高回転・低振動の標準ハンドピース。日常的な切削に最適。', 125000.00, 'active', 'https://example.com/images/handpiece.jpg', 0.15, '18x3x3'),
('EQUIP-002', 'エアータービン 高速型', '最高回転数40万回転の高速エアータービン。精密な切削が可能。', 185000.00, 'active', 'https://example.com/images/turbine.jpg', 0.08, '15x2.5x2.5'),
('EQUIP-003', '超音波スケーラー', '歯石除去に最適な超音波スケーラー。パワー調整可能。', 280000.00, 'active', 'https://example.com/images/scaler.jpg', 1.2, '30x15x10'),
('EQUIP-004', '光重合器 LED型', 'LED式の光重合器。コンポジットレジンの重合に使用。', 45000.00, 'active', 'https://example.com/images/curing.jpg', 0.3, '20x8x5'),
('MAT-001', 'コンポジットレジン A2', '審美性の高いコンポジットレジン。A2色。', 8500.00, 'active', 'https://example.com/images/composite.jpg', 0.01, '5x2x1'),
('MAT-002', 'コンポジットレジン A3', '審美性の高いコンポジットレジン。A3色。', 8500.00, 'active', 'https://example.com/images/composite-a3.jpg', 0.01, '5x2x1'),
('MAT-003', 'アルジネート印象材 標準', 'アルジネート系の印象材。標準硬化時間。', 3200.00, 'active', 'https://example.com/images/alginate.jpg', 0.5, '20x15x10'),
('MAT-004', 'シリコーン印象材 高精度', '高精度なシリコーン印象材。精密な印象が可能。', 12500.00, 'active', 'https://example.com/images/silicone.jpg', 0.3, '15x10x8'),
('MAT-005', 'グラスアイオノマーセメント', 'フッ素含有のグラスアイオノマーセメント。', 4200.00, 'active', 'https://example.com/images/cement.jpg', 0.05, '8x5x3'),
('MAT-006', 'アマルガム 標準', '充填用アマルガム。標準サイズ。', 2800.00, 'active', 'https://example.com/images/amalgam.jpg', 0.1, '10x8x5'),
('MED-001', '消毒用エタノール 80% 500ml', '手指・器具の消毒に使用するエタノール。', 1200.00, 'active', 'https://example.com/images/ethanol.jpg', 0.5, '10x8x15'),
('MED-002', 'リドカイン注射液 2% 1.8ml', '局所麻酔用リドカイン注射液。', 350.00, 'active', 'https://example.com/images/lidocaine.jpg', 0.002, '1x1x5'),
('MED-003', 'グルコン酸クロルヘキシジン 0.2%', 'うがい薬・消毒薬として使用。', 2800.00, 'active', 'https://example.com/images/chx.jpg', 0.5, '12x8x18'),
('MED-004', '過酸化水素水 3% 500ml', '洗浄・消毒に使用する過酸化水素水。', 850.00, 'active', 'https://example.com/images/h2o2.jpg', 0.5, '10x8x15'),
('SUP-001', '使い捨てグローブ ニトリル Mサイズ', 'ニトリル製の使い捨てグローブ。Mサイズ。100枚入り。', 2800.00, 'active', 'https://example.com/images/gloves-m.jpg', 0.2, '25x20x5'),
('SUP-002', '使い捨てグローブ ニトリル Lサイズ', 'ニトリル製の使い捨てグローブ。Lサイズ。100枚入り。', 2800.00, 'active', 'https://example.com/images/gloves-l.jpg', 0.2, '25x20x5'),
('SUP-003', 'サージカルマスク 不織布 50枚入り', '医療用サージカルマスク。50枚入り。', 1800.00, 'active', 'https://example.com/images/mask.jpg', 0.1, '20x15x3'),
('SUP-004', '滅菌ガーゼ 5x5cm 100枚入り', '滅菌済みガーゼ。5x5cm。100枚入り。', 1200.00, 'active', 'https://example.com/images/gauze.jpg', 0.05, '15x10x2'),
('SUP-005', '使い捨てエプロン 不織布 50枚入り', '患者用使い捨てエプロン。50枚入り。', 2500.00, 'active', 'https://example.com/images/apron.jpg', 0.3, '30x25x5'),
('SUP-006', 'コップ 紙製 100枚入り', 'うがい用紙コップ。100枚入り。', 800.00, 'active', 'https://example.com/images/cup.jpg', 0.1, '20x20x10'),
('CLIN-001', '診療チェア 電動式', '電動昇降式の診療チェア。快適な診療環境を提供。', 850000.00, 'active', 'https://example.com/images/chair.jpg', 150.0, '200x80x120'),
('CLIN-002', '器具トレー ステンレス', '滅菌可能なステンレス製器具トレー。', 3500.00, 'active', 'https://example.com/images/tray.jpg', 0.5, '30x20x3'),
('CLIN-003', '吸引チップ 使い捨て 100本入り', '吸引用の使い捨てチップ。100本入り。', 1800.00, 'active', 'https://example.com/images/suction.jpg', 0.1, '25x15x5'),
('XRAY-001', 'X線フィルム パノラマ 24x30mm', 'パノラマX線用フィルム。24x30mm。100枚入り。', 15000.00, 'active', 'https://example.com/images/film-pano.jpg', 0.5, '30x25x5'),
('XRAY-002', 'X線フィルム デンタル 31x41mm', 'デンタルX線用フィルム。31x41mm。100枚入り。', 12000.00, 'active', 'https://example.com/images/film-dental.jpg', 0.4, '25x20x5'),
('XRAY-003', 'X線現像液 セット', 'X線フィルム現像用の現像液セット。', 8500.00, 'active', 'https://example.com/images/developer.jpg', 2.0, '20x15x25'),
('XRAY-004', 'X線防護エプロン 鉛入り', 'X線撮影時の防護用エプロン。鉛入り。', 45000.00, 'active', 'https://example.com/images/lead-apron.jpg', 5.0, '80x60x2'),
-- 歯列矯正関連商品
('ORTHO-001', 'メタルブラケット 標準型', 'ステンレス製の標準メタルブラケット。確実な矯正力が得られます。', 850.00, 'active', 'https://example.com/images/metal-bracket.jpg', 0.001, '3x3x2'),
('ORTHO-002', 'セラミックブラケット 審美型', '審美性の高いセラミックブラケット。目立ちにくい透明感のある素材。', 1200.00, 'active', 'https://example.com/images/ceramic-bracket.jpg', 0.001, '3x3x2'),
('ORTHO-003', 'アーチワイヤー ニッケルチタン 0.014インチ', '形状記憶合金製のアーチワイヤー。初期段階の矯正に使用。', 3500.00, 'active', 'https://example.com/images/niti-wire-014.jpg', 0.01, '30x0.5x0.5'),
('ORTHO-004', 'アーチワイヤー ステンレス 0.018インチ', 'ステンレス製のアーチワイヤー。中後期の矯正に使用。', 2800.00, 'active', 'https://example.com/images/ss-wire-018.jpg', 0.01, '30x0.5x0.5'),
('ORTHO-005', 'リテーナー ハーレー型', '矯正後の保定用リテーナー。ハーレー型。', 15000.00, 'active', 'https://example.com/images/hawley-retainer.jpg', 0.05, '10x8x3'),
('ORTHO-006', 'リテーナー クリアリテーナー', '透明なマウスピース型リテーナー。審美性が高い。', 25000.00, 'active', 'https://example.com/images/clear-retainer.jpg', 0.03, '8x6x2'),
('ORTHO-007', 'エラスティック 中サイズ', '矯正用エラスティック。中サイズ。100本入り。', 1200.00, 'active', 'https://example.com/images/elastic-medium.jpg', 0.01, '10x5x1'),
('ORTHO-008', 'エラスティック 大サイズ', '矯正用エラスティック。大サイズ。100本入り。', 1200.00, 'active', 'https://example.com/images/elastic-large.jpg', 0.01, '12x6x1'),
('ORTHO-009', 'バンド 上顎用 標準サイズ', '上顎用の矯正バンド。標準サイズ。', 1800.00, 'active', 'https://example.com/images/band-upper.jpg', 0.005, '5x3x1'),
('ORTHO-010', 'バンド 下顎用 標準サイズ', '下顎用の矯正バンド。標準サイズ。', 1800.00, 'active', 'https://example.com/images/band-lower.jpg', 0.005, '5x3x1'),
('ORTHO-011', '矯正用セメント 光重合型', 'ブラケット固定用の光重合型セメント。', 4500.00, 'active', 'https://example.com/images/ortho-cement.jpg', 0.05, '8x5x3'),
('ORTHO-012', 'インビザライン アライナー 上顎', '透明マウスピース型矯正装置。上顎用。', 150000.00, 'active', 'https://example.com/images/invisalign-upper.jpg', 0.02, '8x6x2'),
('ORTHO-013', 'インビザライン アライナー 下顎', '透明マウスピース型矯正装置。下顎用。', 150000.00, 'active', 'https://example.com/images/invisalign-lower.jpg', 0.02, '8x6x2'),
('ORTHO-014', 'リンガルアーチ 標準型', '舌側からの矯正用リンガルアーチ。標準型。', 12000.00, 'active', 'https://example.com/images/lingual-arch.jpg', 0.05, '15x2x1'),
('ORTHO-015', 'ヘッドギア 頸部固定型', '上顎前突の矯正用ヘッドギア。頸部固定型。', 35000.00, 'active', 'https://example.com/images/headgear.jpg', 0.3, '30x20x10')
ON CONFLICT (product_code) DO NOTHING;

-- 在庫データの初期データ
INSERT INTO product_stocks (product_id, quantity)
SELECT p.id, 
    CASE p.product_code
        WHEN 'EQUIP-001' THEN 5
        WHEN 'EQUIP-002' THEN 3
        WHEN 'EQUIP-003' THEN 2
        WHEN 'EQUIP-004' THEN 8
        WHEN 'MAT-001' THEN 50
        WHEN 'MAT-002' THEN 45
        WHEN 'MAT-003' THEN 100
        WHEN 'MAT-004' THEN 30
        WHEN 'MAT-005' THEN 60
        WHEN 'MAT-006' THEN 80
        WHEN 'MED-001' THEN 200
        WHEN 'MED-002' THEN 500
        WHEN 'MED-003' THEN 150
        WHEN 'MED-004' THEN 180
        WHEN 'SUP-001' THEN 500
        WHEN 'SUP-002' THEN 450
        WHEN 'SUP-003' THEN 300
        WHEN 'SUP-004' THEN 400
        WHEN 'SUP-005' THEN 200
        WHEN 'SUP-006' THEN 600
        WHEN 'CLIN-001' THEN 1
        WHEN 'CLIN-002' THEN 20
        WHEN 'CLIN-003' THEN 250
        WHEN 'XRAY-001' THEN 80
        WHEN 'XRAY-002' THEN 120
        WHEN 'XRAY-003' THEN 15
        WHEN 'XRAY-004' THEN 3
        WHEN 'ORTHO-001' THEN 200
        WHEN 'ORTHO-002' THEN 150
        WHEN 'ORTHO-003' THEN 50
        WHEN 'ORTHO-004' THEN 40
        WHEN 'ORTHO-005' THEN 30
        WHEN 'ORTHO-006' THEN 25
        WHEN 'ORTHO-007' THEN 100
        WHEN 'ORTHO-008' THEN 100
        WHEN 'ORTHO-009' THEN 60
        WHEN 'ORTHO-010' THEN 60
        WHEN 'ORTHO-011' THEN 40
        WHEN 'ORTHO-012' THEN 10
        WHEN 'ORTHO-013' THEN 10
        WHEN 'ORTHO-014' THEN 20
        WHEN 'ORTHO-015' THEN 8
        ELSE 0
    END
FROM products p
ON CONFLICT (product_id) DO NOTHING;

