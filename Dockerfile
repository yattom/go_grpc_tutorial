# 1. ビルド用ステージ
FROM golang:latest AS build

# Protobufコンパイラやプラグインをインストール
RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
    && go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# アプリ用ディレクトリを作成し移動
WORKDIR /app

# 依存パッケージだけ先にコピーしてgo.modの内容に従いダウンロード
COPY go.mod go.sum ./
RUN go mod download

# 残りのソースコードをコピー
COPY . .

# .protoファイルからGoコードを生成
# （protoディレクトリにある helloworld.proto を例に）
RUN protoc \
    --go_out=. \
    --go-grpc_out=. \
    proto/helloworld.proto

# gRPCサーバーをビルド
RUN go build -o server ./server

# 2. 実行用ステージ
FROM golang:latest
WORKDIR /app

# ポートを開ける（gRPCで利用予定のポート）
EXPOSE 50051

# ビルドしたバイナリをコピー
COPY --from=build /app/server /app/server

# コンテナ起動時に実行されるコマンド
ENTRYPOINT ["/bin/bash"]

