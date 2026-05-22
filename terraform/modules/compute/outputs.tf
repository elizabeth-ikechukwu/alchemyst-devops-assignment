output "vm1_public_ip" {
  description = "Public IP of VM1 - use this for your curl command"
  value       = aws_instance.vm1_engine.public_ip
}

output "vm1_private_ip" {
  description = "Private IP of VM1"
  value       = aws_instance.vm1_engine.private_ip
}

output "vm2_private_ip" {
  description = "Private IP of VM2 (caller worker)"
  value       = aws_instance.vm2_caller.private_ip
}

output "vm3_private_ip" {
  description = "Private IP of VM3 (inference worker)"
  value       = aws_instance.vm3_inference.private_ip
}