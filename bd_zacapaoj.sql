-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 17-10-2024 a las 11:30:12
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
