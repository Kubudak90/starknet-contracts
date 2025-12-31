# Ekubo Protocol - EVM Adaptation

Bu dizin, Starknet üzerinde çalışan Ekubo Protocol'ün EVM (Ethereum Virtual Machine) uyumlu Solidity versiyonunu içermektedir.

## 🎯 Proje Hakkında

Ekubo Protocol, concentrated liquidity (yoğunlaştırılmış likidite) modelini kullanan bir AMM (Automated Market Maker) protokolüdür. Bu implementasyon, orijinal Cairo kodunun mimarisini koruyarak EVM uyumlu hale getirilmiştir.

## 📁 Dizin Yapısı

```
contracts/
├── core/              # Ana kontratlar
│   ├── EkuboCore.sol      # Ana AMM motoru
│   ├── EkuboPositions.sol # NFT tabanlı pozisyon yönetimi
│   └── EkuboRouter.sol    # Multi-hop swap router
├── types/             # Veri yapıları
│   └── DataTypes.sol      # Tüm core data type'lar
├── libraries/         # Matematik kütüphaneleri
│   ├── TickMath.sol       # Tick ↔ sqrt price dönüşümleri
│   └── LiquidityMath.sol  # Likidite hesaplamaları
└── interfaces/        # Arayüzler
    └── ICore.sol          # Core kontrat arayüzü
```

## 🏗️ Mimari Özellikler

### 1. **Concentrated Liquidity (Uniswap V3 Benzeri)**
- Likidite sağlayıcıları, sermayelerini belirli fiyat aralıklarında yoğunlaştırabilir
- Tick-based sistem kullanılarak verimli fiyat takibi
- Bitmap optimizasyonu ile gas tasarrufu

### 2. **Locker Pattern**
- Reentrancy koruması için ReentrancyGuard kullanımı
- Callback mekanizması ile güvenli state yönetimi
- Token delta tracking sistemi

### 3. **NFT-Based Positions**
- Her likidite pozisyonu bir ERC721 NFT olarak temsil edilir
- Pozisyonların kolayca transfer edilebilmesi
- Referrer tracking sistemi

### 4. **Extension System**
- Hook sistemi ile genişletilebilir mimari
- TWAMM, Limit Orders gibi ek özellikler için hazır
- Before/After callback'ler

## 🔑 Ana Kontratlar

### EkuboCore.sol
Ana AMM motoru. Temel işlevler:
- Pool initialization ve yönetimi
- Liquidity position güncellemeleri (ekleme/çıkarma)
- Swap execution
- Fee collection ve dağıtımı
- Protocol fee yönetimi

**Önemli Fonksiyonlar:**
```solidity
function initializePool(PoolKey calldata poolKey, int128 initialTick) external returns (uint256)
function updatePosition(PoolKey calldata poolKey, UpdatePositionParameters calldata params) external returns (Delta memory)
function swap(PoolKey calldata poolKey, SwapParameters calldata params) external returns (Delta memory)
function collectFees(PoolKey calldata poolKey, bytes32 salt, Bounds calldata bounds) external returns (Delta memory)
```

### EkuboPositions.sol
NFT tabanlı pozisyon yönetimi:
- Position minting (NFT oluşturma)
- Liquidity deposit/withdrawal
- Fee collection
- Referrer tracking

**Önemli Fonksiyonlar:**
```solidity
function mint() external returns (uint64)
function deposit(uint64 tokenId, PoolKey calldata poolKey, Bounds calldata bounds, uint128 minLiquidity) external returns (uint128)
function withdraw(uint64 tokenId, PoolKey calldata poolKey, Bounds calldata bounds, uint128 liquidity, uint128 minToken0, uint128 minToken1, bool collectFees) external returns (uint128, uint128)
function mintAndDeposit(PoolKey calldata poolKey, Bounds calldata bounds, uint128 minLiquidity) external returns (uint64, uint128)
```

### EkuboRouter.sol
Multi-hop swap router:
- Single-hop swaps
- Multi-hop swaps (birden fazla pool üzerinden)
- Batch swap execution
- Quote (simülasyon) fonksiyonları

**Önemli Fonksiyonlar:**
```solidity
function swap(RouteNode calldata node, TokenAmount calldata tokenAmount) external returns (Delta memory)
function multihopSwap(RouteNode[] calldata route, TokenAmount calldata tokenAmount) external returns (Delta[] memory)
function quoteSwap(RouteNode calldata node, TokenAmount calldata tokenAmount) external returns (Delta memory)
```

## 🔧 Kullanım Örnekleri

### Pool Oluşturma
```solidity
DataTypes.PoolKey memory poolKey = DataTypes.PoolKey({
    token0: address(tokenA),  // tokenA < tokenB (sıralı)
    token1: address(tokenB),
    fee: 3000000000000000000,  // 0.3% = 2^128 * 0.003
    tickSpacing: 60,
    extension: address(0)
});

int128 initialTick = 0;  // 1:1 fiyat oranı
core.initializePool(poolKey, initialTick);
```

### Likidite Ekleme
```solidity
// 1. Position NFT mint et
uint64 tokenId = positions.mint();

// 2. Token'ları approve et
tokenA.approve(address(positions), amount0);
tokenB.approve(address(positions), amount1);

// 3. Likidite ekle
DataTypes.Bounds memory bounds = DataTypes.Bounds({
    lower: -1000,  // Alt fiyat limiti
    upper: 1000    // Üst fiyat limiti
});

uint128 liquidity = positions.deposit(
    tokenId,
    poolKey,
    bounds,
    minLiquidity
);
```

### Swap Yapma
```solidity
// Router üzerinden swap
EkuboRouter.RouteNode memory route = EkuboRouter.RouteNode({
    poolKey: poolKey,
    sqrtRatioLimit: 0,  // 0 = limit yok
    skipAhead: 0
});

EkuboRouter.TokenAmount memory tokenAmount = EkuboRouter.TokenAmount({
    token: address(tokenA),
    amount: 1000000  // Exact input
});

// Token'ı approve et
tokenA.approve(address(router), 1000000);

// Swap yap
DataTypes.Delta memory delta = router.swap(route, tokenAmount);
```

## 🔄 Cairo → Solidity Dönüşüm Notları

### Type Mapping
| Cairo | Solidity |
|-------|----------|
| `i129` | `int256` (veya `int128` uygun yerlerde) |
| `u128` | `uint128` |
| `u256` | `uint256` |
| `ContractAddress` | `address` |
| `felt252` | `bytes32` |
| `Map<K, V>` | `mapping(K => V)` |

### Storage Optimizasyonları
- Cairo'daki `storage_access` → Solidity `mapping` ve `storage` keyword'leri
- Transient storage → Memory değişkenler ve state tracking
- Bitmap optimizasyonları korundu

### Güvenlik İyileştirmeleri
- Cairo'daki assert'ler → Solidity `require` statements
- Locker pattern → `ReentrancyGuard` + callback sistem
- Ownership → OpenZeppelin `Ownable` kontrat

## ⚠️ Önemli Notlar

1. **Swap Logic**: Core kontratındaki `_executeSwap` fonksiyonu basitleştirilmiş bir placeholder'dır. Production kullanımı için tam swap logic implementasyonu gereklidir.

2. **Tick Bitmap**: Bitmap-based tick arama fonksiyonları (`_nextInitializedTick`, `_prevInitializedTick`) tam implementasyonu gerektirmektedir.

3. **Gas Optimization**: Production ortamında daha fazla gas optimizasyonu yapılabilir.

4. **Testing**: Kontratların kapsamlı test edilmesi gerekmektedir.

5. **Audit**: Production kullanımı öncesi profesyonel security audit şarttır.

## 🚀 Geliştirme Yol Haritası

- [x] Core data types
- [x] Math kütüphaneleri
- [x] Core kontrat temel yapısı
- [x] Positions kontrat
- [x] Router kontrat
- [ ] Tam swap logic implementasyonu
- [ ] Tick bitmap optimizasyonları
- [ ] Extension kontratları (TWAMM, Limit Orders)
- [ ] Kapsamlı test suite
- [ ] Gas optimization
- [ ] Security audit

## 📚 Kaynaklar

- [Ekubo Protocol Dokümantasyonu](https://docs.ekubo.org/)
- [Uniswap V3 Whitepaper](https://uniswap.org/whitepaper-v3.pdf)
- [Starknet Cairo Documentation](https://www.cairo-lang.org/)

## 📄 Lisans

MIT License - Orijinal Ekubo Protocol'den uyarlanmıştır.
