-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 17-10-2024 a las 11:31:16
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bd_zacapaoj`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarComprobanteEntrega` (IN `p_numeroEntrega` VARCHAR(15), IN `p_fechaEntrega` DATE, IN `p_codigoProducto` INT, IN `p_cantidadEntrega` INT, IN `p_usuario` VARCHAR(45))   BEGIN
	DECLARE v_idEntrega INT;
    DECLARE ID_produ INT;
    
    SELECT ID INTO ID_produ FROM tbl_registrocompra where tbl_registrocompra.codigoProducto = p_codigoProducto;
    -- Insertar comprobante de entrega
    INSERT INTO tbl_ComprobanteEntrega (numeroEntrega, fechaEntrega)
    VALUES (p_numeroEntrega, p_fechaEntrega);
    
    
    SET v_idEntrega = LAST_INSERT_ID();

    -- Insertar detalle del comprobante
    INSERT INTO tbl_DetalleComprobante (ID_producto, ID_reciboEntrega, cantidadEntrega, usuario)
    VALUES (ID_produ, v_idEntrega, p_cantidadEntrega, p_usuario);
    
    UPDATE tbl_bodega SET tbl_bodega.stock = tbl_bodega.stock - p_cantidadEntrega
    WHERE tbl_bodega.ID_producto = ID_produ;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarDatosBodega` (IN `p_categoria` VARCHAR(45), IN `p_estado` VARCHAR(45), IN `p_codigoProducto` INT, IN `p_seccionBodega` VARCHAR(45), IN `p_stock` INT, IN `p_stockMin` INT, IN `p_usuario` VARCHAR(45))   BEGIN
    DECLARE v_idCategoria INT;
    DECLARE v_idEstado INT;
    DECLARE id_producto INT;

    -- Obtener ID de la categoría si existe
    SELECT ID INTO v_idCategoria FROM tbl_categoria WHERE categoria = p_categoria;
    
    -- Obtener ID del estado si existe
    SELECT ID INTO v_idEstado FROM tbl_estado WHERE estado = p_estado;
    
    -- Obtener ID del producto si existe
    SELECT ID INTO id_producto FROM tbl_registroCompra WHERE codigoProducto = p_codigoProducto;
    
    -- Verificar si se encontraron la categoría, el estado y el producto
    IF v_idCategoria IS NOT NULL AND v_idEstado IS NOT NULL AND id_producto IS NOT NULL THEN
        -- Insertar en la tabla tbl_bodega
        INSERT INTO tbl_bodega (ID_producto, ID_categoria, ID_estado, seccionBodega, stock, stockMin, usuario)
        VALUES (id_producto, v_idCategoria, v_idEstado, p_seccionBodega, p_stock, p_stockMin, p_usuario);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarRegistroCompra` (IN `p_codigoProducto` VARCHAR(20), IN `p_nombreProducto` VARCHAR(45), IN `p_descripcion` VARCHAR(200), IN `p_cantidadProducto` INT, IN `p_usuario` VARCHAR(45), IN `p_numeroRecibo` VARCHAR(20), IN `p_cantidadEntregado` INT, IN `p_fechaEntrega` DATE)   BEGIN
    DECLARE v_idRecibo INT;
    DECLARE p_ID_producto INT;
    -- Insertar nuevo registro de compra
    INSERT INTO tbl_registroCompra (codigoProducto, nombreProducto, descripcion, cantidadProducto, usuario)
    VALUES (p_codigoProducto, p_nombreProducto, p_descripcion, p_cantidadProducto, p_usuario);
    -- Obtener ID del registro de compra insertado
    SET v_idRecibo = LAST_INSERT_ID();

    -- Insertar recibo de entrega
    INSERT INTO tbl_reciboEntrega (numeroRecibo, cantidadEntregado, fechaEntrega)
    VALUES (p_numeroRecibo, p_cantidadEntregado, p_fechaEntrega);
	SET p_ID_producto = LAST_INSERT_ID();
    -- Insertar detalle de entrega
    INSERT INTO tbl_detalleEntrega (ID_producto, ID_recibo)
    VALUES (v_idRecibo, p_ID_producto);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarUsuarioPersonal` (IN `p_nombreCompleto` VARCHAR(60), IN `p_identificacion` VARCHAR(13), IN `p_nombreCargo` VARCHAR(45), IN `p_nombreUsuario` VARCHAR(45), IN `p_contrasena` VARCHAR(32))   BEGIN
    DECLARE v_idPersonal INT;
    DECLARE v_idCargo INT;

    -- Verificar si el nombre de usuario ya existe
    IF EXISTS (SELECT 1 FROM tbl_usuarioPersonal WHERE nombreUsuario = p_nombreUsuario) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de usuario ya existe.';
    ELSE
        -- Iniciar transacción
        START TRANSACTION;

        -- Insertar nueva persona
        INSERT INTO tbl_persona (nombreCompleto, identificacion)
        VALUES (p_nombreCompleto, p_identificacion);
        SET v_idPersonal = LAST_INSERT_ID();

        -- Obtener ID del cargo
        SELECT ID INTO v_idCargo
        FROM tbl_cargosUsuarios
        WHERE nombreCargo = p_nombreCargo;

        -- Insertar nuevo usuario personal
        INSERT INTO tbl_usuarioPersonal (ID_personal, ID_cargo, nombreUsuario, contrasena)
        VALUES (v_idPersonal, v_idCargo, p_nombreUsuario, p_contrasena);

        -- Commit de la transacción
        COMMIT;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesar_retiro` (IN `p_codigoProducto` VARCHAR(255), IN `p_cantidadRetiro` INT, OUT `p_resultado` INT)   BEGIN
    DECLARE `cantidadDisponible` INT;
    DECLARE `cantidadRestante` INT;
    DECLARE `id_detalle` INT;
    DECLARE `cantidadActual` INT;
    DECLARE cur CURSOR FOR
        SELECT det.ID, det.cantidad
        FROM bd_zacapaoj.tbl_detalleproducto AS det
        JOIN bd_zacapaoj.tbl_registrocompra AS com
        ON det.ID_producto = com.ID
        WHERE com.codigoProducto = p_codigoProducto
        ORDER BY det.cantidad DESC, det.ID ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET cantidadRestante = 0;

    -- Inicializar resultado
    SET p_resultado = 1;

    -- Obtener la cantidad total disponible para el producto específico
    SELECT COALESCE(SUM(det.cantidad), 0) INTO cantidadDisponible
    FROM bd_zacapaoj.tbl_registrocompra AS com
    LEFT JOIN bd_zacapaoj.tbl_detalleproducto AS det
    ON com.ID = det.ID_producto
    WHERE com.codigoProducto = p_codigoProducto;

    -- Verificar la cantidad de retiro
    IF p_cantidadRetiro > cantidadDisponible THEN
        -- La cantidad de retiro es mayor que la cantidad disponible
        SET p_resultado = 0; -- Indica que el stock es insuficiente
    ELSE
        -- La cantidad de retiro es menor o igual a la cantidad disponible
        SET cantidadRestante = p_cantidadRetiro;

        OPEN cur;

        read_loop: LOOP
            FETCH cur INTO id_detalle, cantidadActual;
            
            IF cantidadRestante = 0 THEN
                LEAVE read_loop;
            END IF;

            IF cantidadActual <= cantidadRestante THEN
                -- Retirar toda la cantidad de este registro
                UPDATE bd_zacapaoj.tbl_detalleproducto
                SET cantidad = 0
                WHERE ID = id_detalle;

                SET cantidadRestante = cantidadRestante - cantidadActual;
            ELSE
                -- Retirar parcialmente de este registro
                UPDATE bd_zacapaoj.tbl_detalleproducto
                SET cantidad = cantidad - cantidadRestante
                WHERE ID = id_detalle;

                SET cantidadRestante = 0;
            END IF;
        END LOOP;

        CLOSE cur;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_ActualizarCargarBodega` (IN `Cod_producto_b` VARCHAR(20), IN `Categoria_b` VARCHAR(45), IN `seccionBod_b` VARCHAR(45), IN `stokMin_b` INT, IN `usuario_b` VARCHAR(45))   BEGIN 	
    DECLARE ID_producto_b INT;
    DECLARE ID_categoria_n INT; 
    
    -- Capturamos el ID del producto 
    SELECT ID INTO ID_producto_b 
    FROM tbl_registrocompra 
    WHERE codigoProducto = Cod_producto_b;
    
    -- Capturamos la categoría
    SELECT ID INTO ID_categoria_n 
    FROM tbl_categoria 
    WHERE categoria = Categoria_b;
        
    -- Actualizamos datos en la tabla tbl_bodega
    UPDATE tbl_bodega
    SET 
        ID_categoria = ID_categoria_n,
        seccionBodega = seccionBod_b,
        stockMin = stokMin_b,
        usuario = usuario_b
    WHERE 
        ID_producto = ID_producto_b;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_ActualizarUsuarios` (IN `p_nombreCompleto` VARCHAR(45), IN `p_identificacionAntigua` VARCHAR(20), IN `p_identificacionNueva` VARCHAR(20), IN `p_nombreCargo` VARCHAR(45), IN `p_nombreUsuario` VARCHAR(45), IN `p_contrasena` VARCHAR(45))   BEGIN
    DECLARE v_idPersonal INT;
    DECLARE v_idCargo INT;

    -- Iniciar transacción
    START TRANSACTION;

    -- Obtener ID de la persona a partir de la identificación antigua
    SELECT ID INTO v_idPersonal
    FROM tbl_persona
    WHERE identificacion = p_identificacionAntigua;

    -- Actualizar los datos de la persona, incluida la identificación
    UPDATE tbl_persona
    SET nombreCompleto = p_nombreCompleto, identificacion = p_identificacionNueva
    WHERE ID = v_idPersonal;

    -- Obtener ID del cargo
    SELECT ID INTO v_idCargo
    FROM tbl_cargosUsuarios
    WHERE nombreCargo = p_nombreCargo;

    -- Actualizar los datos del usuario personal
    UPDATE tbl_usuarioPersonal
    SET ID_cargo = v_idCargo, nombreUsuario = p_nombreUsuario, contrasena = p_contrasena
    WHERE ID_personal = v_idPersonal;

    -- Commit de la transacción
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_AgregarProductoCarro` (IN `cantidad_d` INT, IN `Cod_producto` VARCHAR(255), OUT `resultado` INT)   BEGIN
    DECLARE cantE INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET resultado = -1; -- Error en la base de datos
    END;

    START TRANSACTION;

    SELECT cantidadProducto INTO cantE
    FROM tbl_registrocompra 
    WHERE codigoProducto = Cod_producto;

    IF (cantE >= cantidad_d) THEN
        UPDATE tbl_registrocompra
        SET cantidadProducto = cantidadProducto - cantidad_d
        WHERE codigoProducto = Cod_producto;

        COMMIT;
        SET resultado = 1; -- Operación exitosa
    ELSE
        ROLLBACK;
        SET resultado = 0; -- No hay suficiente stock
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_CargarBodega` (IN `Cod_producto_b` VARCHAR(20), IN `Categoria_b` VARCHAR(45), IN `seccionBod_b` VARCHAR(45), IN `stokMin_b` INT, IN `usuario_b` VARCHAR(45))   BEGIN 	
    DECLARE ID_producto_b INT;
    DECLARE ID_categoria_n INT; 
        
    -- Capturamos el ID del producto 
    SELECT ID INTO ID_producto_b 
    FROM tbl_registrocompra 
    WHERE codigoProducto = Cod_producto_b;
    
    -- Capturamos la categoría
    SELECT ID INTO ID_categoria_n 
    FROM tbl_categoria 
    WHERE categoria = Categoria_b;
        
    -- Insertamos datos en la tabla tbl_bodega
    INSERT INTO tbl_bodega (
        ID_producto, 
        ID_categoria, 
        seccionBodega,
        stockMin, 
        usuario
    ) 
    VALUES (
        ID_producto_b, 
        ID_categoria_n, 
        seccionBod_b, 
        stokMin_b, 
        usuario_b
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_eliminarProductoDetalle` (IN `Cantidad_p` INT, IN `CodigoP_p` VARCHAR(20), IN `Comprobante_p` INT)   BEGIN 
    DECLARE ID_producto_b INT;
    DECLARE ID_detalle_b INT;
    
    -- BUSCAR EL PRODUCTO
    SELECT ID INTO ID_producto_b 
    FROM tbl_registrocompra 
    WHERE codigoProducto = CodigoP_p;
    
    -- OBTENER EL PRIMER REGISTRO DE tbl_detalleproducto A ACTUALIZAR
    SELECT ID INTO ID_detalle_b 
    FROM tbl_detalleproducto 
    WHERE ID_producto = ID_producto_b
    LIMIT 1;
    
    -- HACER EL UPDATE SOLO A ESA FILA
    UPDATE tbl_detalleproducto 
    SET cantidad = cantidad + Cantidad_p
    WHERE ID = ID_detalle_b;
    
    -- ELIMINAR EL PRODUCTO DE LA TABLA tbl_detalleentrega
    DELETE FROM tbl_detalleentrega 
    WHERE ID_producto = ID_producto_b 
    AND ID_recibo = Comprobante_p;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_GuardarComprobante` (IN `Usuario_b` VARCHAR(45), IN `comprobante_b` VARCHAR(20), IN `Cod_producto_b` VARCHAR(20), IN `cantidad_b` INT)   BEGIN 
    DECLARE nombreUsuario VARCHAR(100);
	DECLARE id_producto_b INT;
    -- Buscamos el nombre del usuario y lo almacenamos en una variable local
    SELECT PE.nombreCompleto 
    INTO nombreUsuario
    FROM tbl_usuariopersonal AS US 
    INNER JOIN tbl_persona AS PE 
    ON US.ID_personal = PE.ID
    WHERE US.nombreUsuario = Usuario_b; 

    -- Insertamos en tbl_entregaproductocliente el comprobante y el nombre del usuario
    INSERT INTO tbl_entregaproductocliente (comprobante, usuario)
    VALUES (comprobante_b, nombreUsuario);
	
    SELECT ID INTO id_producto_b
    FROM tbl_registrocompra
    WHERE tbl_registrocompra.codigoProducto = Cod_producto_b;
    -- Insertamos el producto en tbl_detalleentrega con el código de producto y el comprobante
    INSERT INTO tbl_detalleentrega (ID_producto, ID_recibo, cantidad)
    VALUES (id_producto_b, comprobante_b, cantidad_b);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_GuardarDetalleProducto` (IN `comprobante_b` VARCHAR(20), IN `Cod_producto_b` VARCHAR(20), IN `cantidad_b` INT)   BEGIN 
DECLARE id_producto_b INT;
	SELECT ID INTO id_producto_b
    FROM tbl_registrocompra WHERE tbl_registrocompra.codigoProducto = Cod_producto_b;
    
    -- Insertamos el producto en tbl_detalleentrega con el código de producto y el comprobante
    INSERT INTO tbl_detalleentrega (ID_producto, ID_recibo, cantidad)
    VALUES (id_producto_b, comprobante_b, cantidad_b);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_guardarProducto` (IN `codigo_i` VARCHAR(20), IN `nombre_i` VARCHAR(45), IN `descripcion_i` VARCHAR(200), IN `cantidad_i` INT)   BEGIN
    DECLARE id_producto INT;
    
    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK; -- Revertir la transacción si hay un error
    END;

    -- Iniciar la transacción
    START TRANSACTION;

    -- Verificar si el producto ya existe en la tabla tbl_registrocompra
    SELECT ID INTO id_producto FROM tbl_registrocompra WHERE codigoProducto = codigo_i;
    
    IF id_producto IS NULL THEN
        -- Si no existe, inserta el nuevo producto en tbl_registrocompra
        INSERT INTO tbl_registrocompra (codigoProducto, nombreProducto, descripcion)
        VALUES (codigo_i, nombre_i, descripcion_i);
        
        -- Obtener el ID del nuevo producto insertado
        SELECT ID INTO id_producto FROM tbl_registrocompra WHERE codigoProducto = codigo_i;
        
        -- Insertar en tbl_detalleproducto usando el nuevo ID de producto
        INSERT INTO tbl_detalleproducto (ID_producto, cantidad) VALUES (id_producto, cantidad_i);
        
    ELSE
        -- Si el producto ya existe, insertar directamente en tbl_detalleproducto
        INSERT INTO tbl_detalleproducto (ID_producto, cantidad) VALUES (id_producto, cantidad_i);
    END IF;

    -- Confirmar la transacción
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_insertarUsuarios` (IN `contrasenaUSUARIO` VARCHAR(50), IN `usuarioUSUARIO` VARCHAR(50), IN `nombreCOMPLETO` VARCHAR(60), IN `identificacion` VARCHAR(13), IN `nombreCargo` VARCHAR(45))   BEGIN
    DECLARE ID_cargo INT;
    DECLARE ID_persona INT;

    -- Comenzamos buscando el cargo para luego guardar su ID
    SELECT ID INTO ID_cargo 
    FROM tbl_cargosusuarios 
    WHERE tbl_cargosusuarios.nombreCargo = nombreCargo
    LIMIT 1;

    -- Manejo de error si no se encuentra el cargo
    IF ID_cargo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cargo no encontrado';
    END IF;

    -- Guardamos los datos personales del usuario para luego obtener el ID del mismo
    INSERT INTO tbl_persona (nombreCompleto, identificacion) 
    VALUES (nombreCOMPLETO, identificacion);

    -- Obtenemos el ID de la persona recién insertada
    SELECT ID INTO ID_persona 
    FROM tbl_persona 
    WHERE tbl_persona.identificacion = identificacion
    ORDER BY ID DESC
    LIMIT 1;

    -- Inserción del usuario en la tabla tbl_usuariopersonal
    INSERT INTO tbl_usuariopersonal (ID_personal, ID_cargo, nombreUsuario, contrasena)
    VALUES (ID_persona, ID_cargo, usuarioUSUARIO, contrasenaUSUARIO);

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_bodega`
--

CREATE TABLE `tbl_bodega` (
  `ID` int(11) NOT NULL,
  `ID_producto` int(11) NOT NULL,
  `ID_categoria` int(11) NOT NULL,
  `seccionBodega` varchar(45) NOT NULL,
  `stockMin` int(11) NOT NULL,
  `fechaCommit` timestamp NOT NULL DEFAULT current_timestamp(),
  `usuario` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_bodega`
--

INSERT INTO `tbl_bodega` (`ID`, `ID_producto`, `ID_categoria`, `seccionBodega`, `stockMin`, `fechaCommit`, `usuario`) VALUES
(10, 15, 1, 'SEC01', 10, '2024-09-16 21:44:19', 'carlos'),
(11, 16, 1, 'SEC01', 10, '2024-09-16 22:44:22', 'carlos'),
(13, 18, 2, 'SEC01', 10, '2024-10-17 04:28:18', 'carlos');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_cargosusuarios`
--

CREATE TABLE `tbl_cargosusuarios` (
  `ID` int(11) NOT NULL,
  `nombreCargo` varchar(45) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_cargosusuarios`
--

INSERT INTO `tbl_cargosusuarios` (`ID`, `nombreCargo`, `estado`) VALUES
(1, 'Administrador', 1),
(2, 'Encargado de Bodega', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_categoria`
--

CREATE TABLE `tbl_categoria` (
  `ID` int(11) NOT NULL,
  `categoria` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_categoria`
--

INSERT INTO `tbl_categoria` (`ID`, `categoria`) VALUES
(1, 'Herramientas'),
(2, 'Limpieza'),
(4, 'Tubería'),
(5, 'Cableado'),
(6, 'Plomeria');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_comprobanteentrega`
--

CREATE TABLE `tbl_comprobanteentrega` (
  `ID` int(11) NOT NULL,
  `numeroEntrega` varchar(15) NOT NULL,
  `fechaEntrega` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_comprobanteentrega`
--

INSERT INTO `tbl_comprobanteentrega` (`ID`, `numeroEntrega`, `fechaEntrega`) VALUES
(4, 'ENT001', '2024-05-17');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_detallecomprobante`
--

CREATE TABLE `tbl_detallecomprobante` (
  `ID` int(11) NOT NULL,
  `ID_producto` int(11) NOT NULL,
  `ID_reciboEntrega` int(11) NOT NULL,
  `cantidadEntrega` int(11) NOT NULL,
  `usuario` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_detalleentrega`
--

CREATE TABLE `tbl_detalleentrega` (
  `ID` int(11) NOT NULL,
  `ID_producto` int(11) NOT NULL,
  `ID_recibo` varchar(20) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `fechaComit` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_detalleentrega`
--

INSERT INTO `tbl_detalleentrega` (`ID`, `ID_producto`, `ID_recibo`, `cantidad`, `fechaComit`) VALUES
(79, 15, '49', 1, '2024-10-16 09:22:35'),
(83, 16, '52', 1, '2024-10-16 10:05:07'),
(85, 16, '53', 2, '2024-10-17 04:42:48'),
(86, 18, '53', 2, '2024-10-17 04:42:54'),
(87, 15, '53', 2, '2024-10-17 04:42:58');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_detalleproducto`
--

CREATE TABLE `tbl_detalleproducto` (
  `ID` int(11) NOT NULL,
  `ID_producto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_detalleproducto`
--

INSERT INTO `tbl_detalleproducto` (`ID`, `ID_producto`, `cantidad`, `fecha`) VALUES
(1, 15, 3, '2024-09-16 21:02:26'),
(2, 15, 2, '2024-09-16 22:00:29'),
(3, 15, 0, '2024-09-16 22:10:06'),
(4, 16, 1, '2024-09-16 22:43:48'),
(6, 18, 398, '2024-10-16 22:30:31');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_entregaproductocliente`
--

CREATE TABLE `tbl_entregaproductocliente` (
  `ID` int(11) NOT NULL,
  `comprobante` varchar(20) NOT NULL,
  `usuario` varchar(45) NOT NULL,
  `fechaEntrega` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_entregaproductocliente`
--

INSERT INTO `tbl_entregaproductocliente` (`ID`, `comprobante`, `usuario`, `fechaEntrega`) VALUES
(5, '5', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(6, '6', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(8, '8', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(10, '10', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(11, '11', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(12, '12', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(13, '13', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(14, '14', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(15, '15', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(16, '16', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(17, '17', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(18, '18', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(19, '19', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(20, '20', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(21, '21', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(22, '22', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(23, '23', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(24, '24', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(25, '25', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(26, '26', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(27, '27', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(28, '28', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(29, '29', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(30, '30', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(31, '31', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(32, '32', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(33, '33', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(34, '34', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(35, '35', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(36, '36', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(37, '37', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(38, '38', 'fabiola', '0000-00-00'),
(39, '39', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(40, '40', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(41, '41', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(42, '42', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(43, '43', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(44, '44', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(45, '45', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(46, '46', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(47, '47', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(48, '48', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(49, '49', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(50, '50', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(51, '51', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(52, '52', 'Carlos Leonel Cruz Lopez', '0000-00-00'),
(53, '53', 'Carlos Leonel Cruz Lopez', '0000-00-00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_persona`
--

CREATE TABLE `tbl_persona` (
  `ID` int(11) NOT NULL,
  `nombreCompleto` varchar(60) NOT NULL,
  `identificacion` varchar(13) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_persona`
--

INSERT INTO `tbl_persona` (`ID`, `nombreCompleto`, `identificacion`) VALUES
(3, 'Carlos Leonel Cruz Lopez', '1234567890123'),
(15, 'Marlon Junior Alvarez Canut', '1234567891234'),
(27, 'fabiola', '3362313421904');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_reciboentrega`
--

CREATE TABLE `tbl_reciboentrega` (
  `ID` int(11) NOT NULL,
  `numeroRecibo` varchar(20) NOT NULL,
  `cantidadEntregado` int(11) NOT NULL,
  `fechaEntrega` date DEFAULT NULL,
  `fechaCommit` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_reciboentrega`
--

INSERT INTO `tbl_reciboentrega` (`ID`, `numeroRecibo`, `cantidadEntregado`, `fechaEntrega`, `fechaCommit`) VALUES
(1, 'REC001', 10, '2024-05-15', '2024-05-14 16:41:18'),
(2, 'REC002', 10, '2024-05-29', '2024-05-30 09:14:47'),
(3, 'REC003', 10, '2024-06-01', '2024-06-01 21:43:10');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_registrocompra`
--

CREATE TABLE `tbl_registrocompra` (
  `ID` int(11) NOT NULL,
  `codigoProducto` varchar(20) NOT NULL,
  `nombreProducto` varchar(45) NOT NULL,
  `descripcion` varchar(200) NOT NULL,
  `fechaCommit` timestamp NOT NULL DEFAULT current_timestamp(),
  `usuario` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_registrocompra`
--

INSERT INTO `tbl_registrocompra` (`ID`, `codigoProducto`, `nombreProducto`, `descripcion`, `fechaCommit`, `usuario`) VALUES
(15, 'COD01', 'Tuberia de 1/2', 'Tubo de 2 metros para cableado electrico', '2024-09-16 21:02:26', ''),
(16, 'COD02', 'Tomacorriente', 'Tomacorriente de 2 puertos', '2024-09-16 22:43:48', ''),
(18, 'COD255', 'Tornillo Tabla yeso ', 'Tornillo de 2 pulgadas', '2024-10-16 22:30:31', '');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tbl_usuariopersonal`
--

CREATE TABLE `tbl_usuariopersonal` (
  `ID` int(11) NOT NULL,
  `ID_personal` int(11) NOT NULL,
  `ID_cargo` int(11) NOT NULL,
  `nombreUsuario` varchar(45) NOT NULL,
  `contrasena` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tbl_usuariopersonal`
--

INSERT INTO `tbl_usuariopersonal` (`ID`, `ID_personal`, `ID_cargo`, `nombreUsuario`, `contrasena`) VALUES
(1, 3, 1, 'carlos', '1234'),
(13, 15, 1, 'marlonJR', '1234'),
(25, 27, 2, 'GFSS', 'fabysalg');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_productoentrega`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_productoentrega` (
`codigoProducto` varchar(20)
,`nombreProducto` varchar(45)
,`descripcion` varchar(200)
,`cantidadProducto` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_verestados`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_verestados` (
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistabodega`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistabodega` (
`codigoProducto` varchar(20)
,`nombreProducto` varchar(45)
,`descripcion` varchar(200)
,`categoria` varchar(45)
,`seccionBodega` varchar(45)
,`cantidadProducto` decimal(32,0)
,`stockMin` int(11)
,`estado` varchar(14)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistacategorias`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistacategorias` (
`categoria` varchar(45)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistacomprobantes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistacomprobantes` (
`nombreProducto` varchar(45)
,`descripcion` varchar(200)
,`cantidad` int(11)
,`ID_recibo` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistaentrega`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistaentrega` (
`ID_recibo` varchar(20)
,`codigoProducto` varchar(20)
,`nombreProducto` varchar(45)
,`cantidad` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistahistorialentregas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistahistorialentregas` (
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistaproducto`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistaproducto` (
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistausuarios`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistausuarios` (
`nombreCompleto` varchar(60)
,`identificacion` varchar(13)
,`nombreCargo` varchar(45)
,`nombreUsuario` varchar(45)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_vistausuariosedit`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vw_vistausuariosedit` (
`nombreCompleto` varchar(60)
,`identificacion` varchar(13)
,`nombreUsuario` varchar(45)
,`contrasena` varchar(32)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_productoentrega`
--
DROP TABLE IF EXISTS `vw_productoentrega`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_productoentrega`  AS SELECT `com`.`codigoProducto` AS `codigoProducto`, `com`.`nombreProducto` AS `nombreProducto`, `com`.`descripcion` AS `descripcion`, coalesce(sum(`det`.`cantidad`),0) AS `cantidadProducto` FROM (`tbl_registrocompra` `com` left join `tbl_detalleproducto` `det` on(`com`.`ID` = `det`.`ID_producto`)) GROUP BY `com`.`codigoProducto`, `com`.`nombreProducto`, `com`.`descripcion` ORDER BY `com`.`codigoProducto` ASC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_verestados`
--
DROP TABLE IF EXISTS `vw_verestados`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_verestados`  AS SELECT `tbl_estado`.`ID` AS `ID`, `tbl_estado`.`estado` AS `estado` FROM `tbl_estado` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistabodega`
--
DROP TABLE IF EXISTS `vw_vistabodega`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistabodega`  AS SELECT `com`.`codigoProducto` AS `codigoProducto`, `com`.`nombreProducto` AS `nombreProducto`, `com`.`descripcion` AS `descripcion`, coalesce(`cat`.`categoria`,'Desconocida') AS `categoria`, coalesce(`bod`.`seccionBodega`,'Desconocida') AS `seccionBodega`, coalesce(sum(`det`.`cantidad`),0) AS `cantidadProducto`, coalesce(`bod`.`stockMin`,0) AS `stockMin`, CASE WHEN coalesce(sum(`det`.`cantidad`),0) < coalesce(`bod`.`stockMin`,0) THEN 'Pocas Unidades' ELSE 'Excelente' END AS `estado` FROM (((`tbl_registrocompra` `com` left join `tbl_bodega` `bod` on(`bod`.`ID_producto` = `com`.`ID`)) left join `tbl_categoria` `cat` on(`cat`.`ID` = `bod`.`ID_categoria`)) left join `tbl_detalleproducto` `det` on(`com`.`ID` = `det`.`ID_producto`)) GROUP BY `com`.`codigoProducto`, `com`.`nombreProducto`, `com`.`descripcion`, coalesce(`cat`.`categoria`,'Desconocida'), coalesce(`bod`.`seccionBodega`,'Desconocida'), coalesce(`bod`.`stockMin`,0) ORDER BY `com`.`codigoProducto` ASC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistacategorias`
--
DROP TABLE IF EXISTS `vw_vistacategorias`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistacategorias`  AS SELECT `tbl_categoria`.`categoria` AS `categoria` FROM `tbl_categoria` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistacomprobantes`
--
DROP TABLE IF EXISTS `vw_vistacomprobantes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistacomprobantes`  AS SELECT `comp`.`nombreProducto` AS `nombreProducto`, `comp`.`descripcion` AS `descripcion`, `entr`.`cantidad` AS `cantidad`, `entr`.`ID_recibo` AS `ID_recibo` FROM ((`tbl_registrocompra` `comp` join `tbl_detalleentrega` `entr` on(`comp`.`ID` = `entr`.`ID_producto`)) join `tbl_entregaproductocliente` `clie` on(`clie`.`ID` = `entr`.`ID_recibo`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistaentrega`
--
DROP TABLE IF EXISTS `vw_vistaentrega`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistaentrega`  AS SELECT `de`.`ID_recibo` AS `ID_recibo`, `re`.`codigoProducto` AS `codigoProducto`, `re`.`nombreProducto` AS `nombreProducto`, `de`.`cantidad` AS `cantidad` FROM (`tbl_detalleentrega` `de` join `tbl_registrocompra` `re` on(`de`.`ID_producto` = `re`.`ID`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistahistorialentregas`
--
DROP TABLE IF EXISTS `vw_vistahistorialentregas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistahistorialentregas`  AS SELECT `comp`.`codigoProducto` AS `codigoProducto`, `compt`.`numeroEntrega` AS `numeroEntrega`, `comp`.`nombreProducto` AS `nombreProducto`, `comp`.`descripcion` AS `descripcion`, `bode`.`stock` AS `stock`, `cate`.`categoria` AS `categoria`, `compt`.`fechaEntrega` AS `fechaEntrega` FROM ((((`tbl_registrocompra` `comp` join `tbl_bodega` `bode` on(`comp`.`ID` = `bode`.`ID_producto`)) join `tbl_detallecomprobante` `reci` on(`reci`.`ID_producto` = `comp`.`ID`)) join `tbl_comprobanteentrega` `compt` on(`compt`.`ID` = `reci`.`ID_reciboEntrega`)) join `tbl_categoria` `cate` on(`cate`.`ID` = `bode`.`ID_categoria`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistaproducto`
--
DROP TABLE IF EXISTS `vw_vistaproducto`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistaproducto`  AS SELECT `tbl_registrocompra`.`codigoProducto` AS `codigoProducto`, `tbl_registrocompra`.`nombreProducto` AS `nombreProducto`, `tbl_registrocompra`.`descripcion` AS `descripcion`, `tbl_registrocompra`.`cantidadProducto` AS `cantidadProducto` FROM `tbl_registrocompra` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistausuarios`
--
DROP TABLE IF EXISTS `vw_vistausuarios`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistausuarios`  AS SELECT `pe`.`nombreCompleto` AS `nombreCompleto`, `pe`.`identificacion` AS `identificacion`, `ca`.`nombreCargo` AS `nombreCargo`, `us`.`nombreUsuario` AS `nombreUsuario` FROM ((`tbl_usuariopersonal` `us` join `tbl_persona` `pe` on(`us`.`ID_personal` = `pe`.`ID`)) join `tbl_cargosusuarios` `ca` on(`us`.`ID_cargo` = `ca`.`ID`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_vistausuariosedit`
--
DROP TABLE IF EXISTS `vw_vistausuariosedit`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_vistausuariosedit`  AS SELECT `pe`.`nombreCompleto` AS `nombreCompleto`, `pe`.`identificacion` AS `identificacion`, `us`.`nombreUsuario` AS `nombreUsuario`, `us`.`contrasena` AS `contrasena` FROM (`tbl_usuariopersonal` `us` join `tbl_persona` `pe` on(`us`.`ID_personal` = `pe`.`ID`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `tbl_bodega`
--
ALTER TABLE `tbl_bodega`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `ID_producto` (`ID_producto`),
  ADD KEY `ID_categoria` (`ID_categoria`);

--
-- Indices de la tabla `tbl_cargosusuarios`
--
ALTER TABLE `tbl_cargosusuarios`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tbl_categoria`
--
ALTER TABLE `tbl_categoria`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tbl_comprobanteentrega`
--
ALTER TABLE `tbl_comprobanteentrega`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tbl_detallecomprobante`
--
ALTER TABLE `tbl_detallecomprobante`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `ID_producto` (`ID_producto`),
  ADD KEY `tbl_detallecomprobante_ibfk_2` (`ID_reciboEntrega`);

--
-- Indices de la tabla `tbl_detalleentrega`
--
ALTER TABLE `tbl_detalleentrega`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tbl_detalleproducto`
--
ALTER TABLE `tbl_detalleproducto`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `ID_producto` (`ID_producto`);

--
-- Indices de la tabla `tbl_entregaproductocliente`
--
ALTER TABLE `tbl_entregaproductocliente`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tbl_persona`
--
ALTER TABLE `tbl_persona`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tbl_reciboentrega`
--
ALTER TABLE `tbl_reciboentrega`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `tbl_registrocompra`
--
ALTER TABLE `tbl_registrocompra`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `codigoProducto` (`codigoProducto`);

--
-- Indices de la tabla `tbl_usuariopersonal`
--
ALTER TABLE `tbl_usuariopersonal`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `nombreUsuario` (`nombreUsuario`),
  ADD KEY `ID_personal` (`ID_personal`),
  ADD KEY `ID_cargo` (`ID_cargo`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `tbl_bodega`
--
ALTER TABLE `tbl_bodega`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `tbl_cargosusuarios`
--
ALTER TABLE `tbl_cargosusuarios`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `tbl_categoria`
--
ALTER TABLE `tbl_categoria`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `tbl_comprobanteentrega`
--
ALTER TABLE `tbl_comprobanteentrega`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `tbl_detallecomprobante`
--
ALTER TABLE `tbl_detallecomprobante`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `tbl_detalleentrega`
--
ALTER TABLE `tbl_detalleentrega`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=88;

--
-- AUTO_INCREMENT de la tabla `tbl_detalleproducto`
--
ALTER TABLE `tbl_detalleproducto`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `tbl_entregaproductocliente`
--
ALTER TABLE `tbl_entregaproductocliente`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- AUTO_INCREMENT de la tabla `tbl_persona`
--
ALTER TABLE `tbl_persona`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT de la tabla `tbl_reciboentrega`
--
ALTER TABLE `tbl_reciboentrega`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `tbl_registrocompra`
--
ALTER TABLE `tbl_registrocompra`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `tbl_usuariopersonal`
--
ALTER TABLE `tbl_usuariopersonal`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `tbl_bodega`
--
ALTER TABLE `tbl_bodega`
  ADD CONSTRAINT `tbl_bodega_ibfk_1` FOREIGN KEY (`ID_producto`) REFERENCES `tbl_registrocompra` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `tbl_bodega_ibfk_2` FOREIGN KEY (`ID_categoria`) REFERENCES `tbl_categoria` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `tbl_detallecomprobante`
--
ALTER TABLE `tbl_detallecomprobante`
  ADD CONSTRAINT `tbl_detallecomprobante_ibfk_1` FOREIGN KEY (`ID_producto`) REFERENCES `tbl_registrocompra` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `tbl_detallecomprobante_ibfk_2` FOREIGN KEY (`ID_reciboEntrega`) REFERENCES `tbl_comprobanteentrega` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `tbl_detalleproducto`
--
ALTER TABLE `tbl_detalleproducto`
  ADD CONSTRAINT `tbl_detalleproducto_ibfk_1` FOREIGN KEY (`ID_producto`) REFERENCES `tbl_registrocompra` (`ID`);

--
-- Filtros para la tabla `tbl_usuariopersonal`
--
ALTER TABLE `tbl_usuariopersonal`
  ADD CONSTRAINT `tbl_usuariopersonal_ibfk_1` FOREIGN KEY (`ID_personal`) REFERENCES `tbl_persona` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `tbl_usuariopersonal_ibfk_2` FOREIGN KEY (`ID_cargo`) REFERENCES `tbl_cargosusuarios` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
