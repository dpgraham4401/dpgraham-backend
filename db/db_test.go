package db

import (
	"database/sql"
	"fmt"
	"github.com/go-playground/assert/v2"
	"github.com/go-testfixtures/testfixtures/v3"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"os"
	"testing"
)

var (
	db       *sql.DB
	fixtures *testfixtures.Loader
)

// TestMain is a special function that runs before any tests are run
func TestMain(m *testing.M) {
	var err error

	// Open connection to the test database.
	db, err = sql.Open("postgres", "dbname=dpgraham_test user=dg password=password123 host=localhost port=5432 sslmode=disable")
	if err != nil {
		fmt.Println(err)
	}

	// migrate database schema
	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		fmt.Println("error getting driver", err)
	}

	migration, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"postgres", driver)
	if err != nil {
		fmt.Println("error creating migrations", err)
	}

	err = migration.Up()
	if err != nil {
		fmt.Println("error migrating")
	}

	fixtures, err = testfixtures.New(
		testfixtures.Database(db),
		testfixtures.Dialect("postgres"),
		testfixtures.Directory("fixtures"),
	)
	if err != nil {
		fmt.Println(err)
	}

	os.Exit(m.Run())
}

func prepareTestDatabase() {
	if err := fixtures.Load(); err != nil {
		fmt.Println(err)
	}
}

func TestQueryArticleById(t *testing.T) {
	prepareTestDatabase()
	article, _ := QueryArticle(db, 1)
	fmt.Println(article)
	assert.Equal(t, article.Id, 1)
}
