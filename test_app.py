from app import add


def main() -> None:
    assert add(10, 20) == 30
    assert add(3, 7) == 10
    print("test success")


if __name__ == "__main__":
    main()
