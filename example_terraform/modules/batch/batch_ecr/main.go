package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"gopkg.in/redis.v5"
)

var readdb *sqlx.DB
var rdb *redis.Client
var redisoption redis.Options

type Prefix struct {
	Prefix        string `json:"prefix"`
	CFurl         string `json:"cfurl"`
	BuildBehavior string `json:"buildbehavior"`
}
type RedisConfig struct {
	RedisEndPoint string `json:"redisendpoint"`
	RedisPort     string `json:"redisport"`
}

type RDSConfig struct {
	ReaderEndPoint string `json:"psqlreaderendpoint"`
	WriterEndPoint string `json:"psqlwriteerendpoint"`
	UserName       string `json:"username"`
	Port           string `json:"psqlport"`
	DBName         string `json:"dbname"`
}

type MongoConfig struct {
	MongoUrl string `json:"mongourl"`
}

type SecretValue struct {
	Password string `json:"password"`
}

var prefix Prefix
var redisconfig RedisConfig
var rdsconfig RDSConfig
var mongoconfig MongoConfig
var secretvalue SecretValue

func init() {
	log.Println("init start")
	log.Println(os.Getenv("prefix"))
	log.Println(os.Getenv("redissecret"))

	json.Unmarshal([]byte(os.Getenv("prefix")), &prefix)
	json.Unmarshal([]byte(os.Getenv("redissecret")), &redisconfig)
	json.Unmarshal([]byte(os.Getenv("rdssecret")), &rdsconfig)
	json.Unmarshal([]byte(os.Getenv("pwsecret")), &secretvalue)
	json.Unmarshal([]byte(os.Getenv("mongourl")), &mongoconfig)
	addr := fmt.Sprintf("%s:%s", redisconfig.RedisEndPoint, redisconfig.RedisPort)
	redisoption = redis.Options{
		Addr:     addr,
		Password: "", // no password set
		DB:       0,  // use default DB
	}
}

func main() {
	log.Println("sub start")
	argsWithProg := os.Args
	argsWithoutProg := os.Args[1:]

	log.Println(argsWithProg)
	log.Println(argsWithoutProg[0])

	log.Println(prefix)
	log.Println(redisconfig)
	log.Println(rdsconfig)
	log.Println(secretvalue)
	log.Println(mongoconfig)
	ConnectToRedis()
	ConnectToDB()
}

func ConnectToRedis() {
	//Initializing redis
	rdb = redis.NewClient(&redisoption)
	ping(rdb)
}

func ping(client *redis.Client) error {
	pong, err := client.Ping().Result()
	if err != nil {
		log.Println("redis err: " + err.Error())
		return err

	}
	log.Println(pong, err)
	// Output: PONG <nil>

	return nil
}

func ConnectToDB() {
	var readdberr error
	readpsqlInfo := fmt.Sprintf("host=%s port=%s user=%s "+"password=%s dbname=%s sslmode=disable", rdsconfig.ReaderEndPoint, rdsconfig.Port, rdsconfig.UserName, secretvalue.Password, rdsconfig.DBName)
	readdb, readdberr = sqlx.Open("postgres", readpsqlInfo)
	if readdb != nil {
		readdb.SetMaxOpenConns(1000) //최대 커넥션
		readdb.SetMaxIdleConns(100)  //대기 커넥션
	}
	if readdberr != nil {
		fmt.Printf("readdberr: %v", readdberr)
		panic(readdberr)
	} else {
		log.Println("DB connected")
	}
}
