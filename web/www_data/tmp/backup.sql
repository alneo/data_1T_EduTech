-- MySQL dump 10.13  Distrib 8.0.40, for Linux (x86_64)
--
-- Host: localhost    Database: edutech
-- ------------------------------------------------------
-- Server version	8.0.40

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `mm_config`
--

DROP TABLE IF EXISTS `mm_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mm_config` (
  `id` int NOT NULL AUTO_INCREMENT,
  `data_c` int NOT NULL,
  `model_classif` varchar(255) NOT NULL,
  `model_prognoz` varchar(255) NOT NULL,
  `model_studyie` varchar(255) NOT NULL,
  `client_config` json NOT NULL,
  `model_config` json NOT NULL,
  `email_config` json NOT NULL,
  `status` tinyint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mm_config`
--

LOCK TABLES `mm_config` WRITE;
/*!40000 ALTER TABLE `mm_config` DISABLE KEYS */;
INSERT INTO `mm_config` VALUES (1,1732636286,'еще не разработали','project_2411_clf','еще не разработали','{\"host\": \"\", \"port\": \"\", \"login\": \"\", \"passw\": \"\", \"database\": \"\"}','{\"host\": \"\", \"path\": \"\", \"port\": \"\", \"login\": \"\", \"passw\": \"\"}','{\"host\": \"\", \"port\": \"\", \"email\": \"\", \"login\": \"\", \"passw\": \"\", \"secur\": \"\"}',0);
/*!40000 ALTER TABLE `mm_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mm_users`
--

DROP TABLE IF EXISTS `mm_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mm_users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `data_c` int NOT NULL,
  `email` varchar(255) NOT NULL,
  `passw` varchar(255) NOT NULL,
  `status` tinyint NOT NULL,
  `dostup` json NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mm_users`
--

LOCK TABLES `mm_users` WRITE;
/*!40000 ALTER TABLE `mm_users` DISABLE KEYS */;
INSERT INTO `mm_users` VALUES (1,1731775090,'admin@1t.ru','53ea7af62d84d192a63436d99aa1a009',99,'[\"students\", \"users\", \"config\", \"stats\", \"model\"]'),(2,1731792295,'demo@1t.ru','d857047c959fd1eb8c733b87dc966ef2',1,'[\"students\", \"logout\", \"config\", \"main\", \"stats\", \"model\"]'),(3,1732691734,'karina@1t.ru','35ae6e4e70ce40e8d403cccf20606cff',1,'[\"students\", \"main\"]');
/*!40000 ALTER TABLE `mm_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-11-27 11:46:43
