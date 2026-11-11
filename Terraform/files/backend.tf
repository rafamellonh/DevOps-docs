terraform {
  backend "s3" {
    bucket = "s3-terraforme-mello"
    key    = "terraforme-mello.tfstate"
    region = "us-east-2"
  }
}
# test