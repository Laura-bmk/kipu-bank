// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title KipuBank
 * @author Laura-bmk
 * @notice Permite a los usuarios depositar y retirar Ether de su "bóveda" personal.
 * @dev Incluye control de reentrancia, límites por transacción y globales.
 * Se aplican las prácticas básicas de seguridad vistas en clase:
 * errores personalizados, patrón checks-effects-interactions y uso de modifiers.
 */
 
contract KipuBank {

    /*////////////////////////////////////////
                   VARIABLES
    /////////////////////////////////////////*/

    /// @notice Dirección del creador del contrato.
    /// @dev Se marca como immutable ya que se fija al desplegar el contrato.
    address public immutable OWNER;

    /// @notice Límite máximo que un usuario puede retirar en una sola transacción.
    /// @dev Fijado en el constructor, no puede modificarse luego.
    uint256 public immutable limitPerTx;

    /// @notice Límite global máximo de fondos que el contrato puede contener.
    /// @dev Evita que el total de depósitos supere un umbral predefinido.
    uint256 public immutable bankCap;

    /// @notice Registra el balance individual de cada usuario.
    /// @dev mapping: dirección del usuario → monto depositado en wei.
    mapping(address => uint256) public balances;

    /// @notice Número total de depósitos realizados.
    uint256 public totalDeposits;

    /// @notice Número total de retiros realizados.
    uint256 public totalWithdrawals;

    /// @notice Bandera para prevenir ataques de reentrancia.
    bool flag;

    /*//////////////////////////////////////////
                      EVENTOS
    /////////////////////////////////////////////*/

    /// @notice se emite cuando un usuario realiza un depósito exitoso.
    /// @param from Dirección del usuario que deposita.
    /// @param amount Monto de Ether depositado (en wei).
    event DepositPerformed(address indexed from, uint256 amount);

    /// @notice Emite cuando un usuario realiza un retiro exitoso.
    /// @param to Dirección del usuario que recibe el retiro.
    /// @param amount Monto de Ether retirado (en wei).
    event WithdrawalPerformed(address indexed to, uint256 amount);

    /*////////////////////////////////////////
                       ERRORES
    /////////////////////////////////////////*/

    /// @notice Error lanzado cuando el monto enviado o solicitado es cero.
    error InvalidAmount();

    /// @notice Error lanzado cuando el depósito excede el límite global del contrato.
    /// @param requested Monto total que se intenta alcanzar.
    /// @param available Límite máximo permitido.
    error BankCapExceeded(uint256 requested, uint256 available);

    /// @notice Error lanzado cuando se intenta retirar más de lo permitido por transacción.
    /// @param requested Monto solicitado por el usuario.
    /// @param limit Límite por transacción definido.
    error ExceedsPerTxLimit(uint256 requested, uint256 limit);

    /// @notice Error lanzado cuando el usuario no tiene fondos suficientes para el retiro.
    /// @param balance Saldo actual del usuario.
    /// @param requested Monto solicitado para retirar.
    error InsufficientBalance(uint256 balance, uint256 requested);

    /// @notice Error lanzado cuando una transferencia de Ether falla.
    /// @param reason Datos devueltos por la llamada fallida.
    error TransactionFailed(bytes reason);

    /*///////////////////////////////////////
                     MODIFICADOR
    /////////////////////////////////////////*/

    /// @notice Previene ataques de reentrancia bloqueando la función mientras se ejecuta.
    modifier reentrancyGuard() {
        if (flag) revert(); // previene reentrada
        flag = true;
        _;
        flag = false;
    }

    /*////////////////////////////////////////
                    CONSTRUCTOR
    /////////////////////////////////////////*/

    /**
     * @notice Inicializa el contrato con los límites definidos.
     * @param _limitPerTx Límite máximo que un usuario puede retirar por transacción.
     * @param _bankCap Límite global total de fondos permitidos en el contrato.
     */
    constructor(uint256 _limitPerTx, uint256 _bankCap) {
        OWNER = msg.sender;
        limitPerTx = _limitPerTx;
        bankCap = _bankCap;
    }

    /*///////////////////////////////////////
                    DEPÓSITOS
    ////////////////////////////////////////*/

    /**
     * @notice Permite enviar Ether al contrato y registrar el depósito del usuario.
     * @dev Sigue el patrón checks-effects-interactions.
     * @custom:error InvalidAmount Si el monto depositado es cero.
     * @custom:error BankCapExceeded Si el nuevo total supera el límite global.
     */
    function deposit() public payable { //cambiado a public para permitir llamadas internas
        if (msg.value == 0) revert InvalidAmount();

        // check: no superar el límite global
        // El Ether (msg.value) ya fue añadido a adress(this).balance al inciar la función 
        //Prevenir que el Ether quede atrapado si se excede el BankCap:
        // Calculando el balance que tendría el contrato sumando el balance previo y el depósito actual.
        // El balance previo se obtiene restando msg.value del balance actual del contrato.
        uint256 balanceBeforeTx = address(this).balance - msg.value;
        uint256 projectedTotal = balanceBeforeTx + msg.value;

        // check: si el balance FUTURO excede el límite global, revierte.
        if (projectedTotal > bankCap) {
            revert BankCapExceeded(projectedTotal, bankCap);
        }


        // effects
        balances[msg.sender] += msg.value;
        totalDeposits++;

        // interaction
        emit DepositPerformed(msg.sender, msg.value);
    }

    /**
     * @notice Permite recibir Ether directamente sin invocar deposit().
     * @dev Redirige la lógica a deposit().
     */
    receive() external payable {
        deposit();
    }

    /**
     * @notice Fallback genérico que también registra depósitos si llega Ether.
     * @dev Se activa si se llama una función inexistente o se envía Ether con datos.
     */
    fallback() external payable {
        deposit();
    }

    /*///////////////////////////////////////
                      RETIROS
    ////////////////////////////////////////*/

    /**
     * @notice Permite retirar una cantidad específica de Ether del balance personal.
     * @dev Usa reentrancyGuard y el patrón checks-effects-interactions.
     * @param amount Cantidad a retirar (en wei).
     * @return data Información devuelta por la llamada de transferencia.
     * @custom:error InvalidAmount Si amount es cero.
     * @custom:error ExceedsPerTxLimit Si amount supera el límite por transacción.
     * @custom:error InsufficientBalance Si el usuario no tiene fondos suficientes.
     */
    function withdraw(uint256 amount)
        external
        reentrancyGuard
        returns (bytes memory data)
    {
        // checks
        if (amount == 0) revert InvalidAmount();
        if (amount > limitPerTx) revert ExceedsPerTxLimit(amount, limitPerTx);

        uint256 userBalance = balances[msg.sender];
        if (amount > userBalance) revert InsufficientBalance(userBalance, amount);

        // effects
        //El estado se actualiza ANTES de la interacción externa
        balances[msg.sender] = userBalance - amount;
        totalWithdrawals++;

        // interactions
        data = _transferEth(msg.sender, amount);

        emit WithdrawalPerformed(msg.sender, amount);
        return data;
    }

    /*///////////////////////////////////////
                 FUNCIÓN PRIVADA
    ////////////////////////////////////////*/

    /**
     * @notice Realiza la transferencia de Ether a una dirección dada.
     * @dev Usa call para enviar Ether y manejar posibles errores de transferencia.
     * @param to Dirección destino que recibe el Ether.
     * @param amount Monto en wei a transferir.
     * @return data Datos devueltos por la llamada externa.
     * @custom:error TransactionFailed Si la transferencia falla.
     */
    function _transferEth(address to, uint256 amount)
        private
        returns (bytes memory)
    {
        //Uso de call para transferir Ether como método más seguro
        (bool success, bytes memory data) = to.call{value: amount}("");
        if (!success) revert TransactionFailed(data);
        return data;
    }

    /*/////////////////////////////////////////
                 FUNCIONES DE CONSULTA
    //////////////////////////////////////////*/

    /**
     * @notice Devuelve el balance total del contrato (en wei).
     * @return Balance actual del contrato.
     */
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Devuelve el saldo actual de un usuario específico.
     * @param account Dirección del usuario a consultar.
     * @return Balance en wei del usuario.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}

// Adress 0xcBdCfc27594745fbaCA662164927a78Bb6e82416