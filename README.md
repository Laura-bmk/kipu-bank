# 🏦 KipuBank

## 📄 Descripción del contrato
KipuBank es un smart contract desarrollado en Solidity que permite a los usuarios depositar y retirar Ether (ETH) de su propia bóveda personal. Cada usuario tiene un balance individual y puede interactuar con el contrato enviando y retirando fondos bajo ciertas condiciones de seguridad.  

El contrato implementa las siguientes características:

- Cada usuario puede depositar Ether en su bóveda personal.  
- Los retiros están limitados por transacción a un monto fijo definido en el despliegue.  
- Existe un límite global de capacidad del banco (`bankCap`) que no puede ser superado.  
- Se registran el número total de depósitos y retiros realizados.  
- Se utilizan errores personalizados para una gestión más eficiente del gas.  
- Se aplica el patrón *checks → effects → interactions* para evitar vulnerabilidades.  
- Incluye un *reentrancy guard* para proteger las operaciones de retiro.  
- Se agregaron comentarios **NatSpec** para documentar el código conforme a buenas prácticas.  

---

## 💰 Funcionalidades principales

### ➕ Depositar ETH

    function deposit() public payable

- Permite a los usuarios enviar Ether al contrato.  
- Aumenta su saldo personal y el contador de depósitos.  
- Requiere que el monto sea mayor a cero y no supere el `bankCap`.  
- Emite el evento `DepositPerformed`.  

También puede depositarse enviando Ether directamente a la dirección del contrato (por `receive()` o `fallback()`).

---

### ➖ Retirar ETH

    function withdraw(uint256 amount) external reentrancyGuard returns (bytes memory)

- Permite retirar fondos de la bóveda personal.  
- Verifica:  
  - Que el monto sea mayor que cero.  
  - Que no supere `limitPerTx`.  
  - Que el usuario tenga saldo suficiente.  
- Aplica *checks → effects → interactions* y emite `WithdrawalPerformed`.  

---

### 🔍 Consultar balances

    function balanceOf(address account) external view returns (uint256)
    function contractBalance() external view returns (uint256)

- `balanceOf(account)` devuelve el saldo de un usuario específico.  
- `contractBalance()` muestra el total de Ether almacenado en el contrato.  

---

## 🧩 Ejemplo de despliegue en Remix

1. Entrá a **Remix IDE**.  
2. Creá un nuevo archivo llamado `KipuBank.sol` y pegá el código completo del contrato.  
3. En el panel izquierdo, seleccioná:  
   - **Compiler version:** 0.8.30  
   - **License:** MIT  
4. Compilá el contrato con el botón **Compile KipuBank.sol**.  
5. En la pestaña **Deploy & Run Transactions**:  
   - Elegí el entorno `Injected Provider - MetaMask`.  
   - Completá los parámetros del constructor:  
     - `_limitPerTx`: `50000000000000000` (0.05 ETH) → límite máximo de retiro por transacción.  
     - `_bankCap`: `1000000000000000000` (1 ETH) → límite global del contrato.  
   - Hacé clic en **Deploy**.  

> 💡 Nota: los valores en wei reflejan las cantidades de ETH para la prueba; se puede ajustar.  

---

## 🌐 Despliegue en testnet (Sepolia)

1. Seleccioná la red correspondiente en **MetaMask**.  
2. Obtené ETH de prueba en un faucet.  
3. Desplegá el contrato desde Remix con los argumentos mencionados.  
4. Copiá la dirección del contrato y verificá su código en **Etherscan**.  

---

## 🏷️ Contrato desplegado

- **Contract address.:**  
  `0xcBdCfc27594745fbaCA662164927a78Bb6e82416`
  
- **Código verificado en Etherscan:**  
  [https://sepolia.etherscan.io/address/0xcBdCfc27594745fbaCA662164927a78Bb6e82416#code](https://sepolia.etherscan.io/address/0xcBdCfc27594745fbaCA662164927a78Bb6e82416#code)  

---

## ⚙️ Interacción posterior

- **Depositá:** ejecutá `deposit()` desde Remix, enviando un valor en wei en el campo *Value*.  
- **Consultá tu saldo:** llamá a `balanceOf(tu_direccion)`.  
- **Retirá:** ejecutá `withdraw(amount)` con un monto permitido por `_limitPerTx`.  
- **Verificá eventos:** en la consola de Remix verás los logs de `DepositPerformed` y `WithdrawalPerformed`.  

> 💡 Tip: los eventos se pueden ver en la pestaña *Terminal* o *Console* de Remix.  

---

## ☕ Área personal

**Documentando mis primeros pasos con Solidity:**  

*Mucho café, muchos errores de compilación y esta sensación permanente…*

<p align="center">
  <img src="https://i.ibb.co/d0zBfCkN/todo-esta-bajo-control.png" width="350">
</p>

```solidity
// return 01010000 01100001 01101110 01101001 01100011 00100001

