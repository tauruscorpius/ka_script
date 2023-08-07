configuration (var.sh):
ka_service_start_duration  : time duration to wait for service start completed.  area [1, 10] default 1.
ka_retry_times : retry times when continually failed to start service, after that, keepalived will hand over vip to other side. area [1,5] default 3.

working principle:

  when one side lost vip, the vrrp prior is 90(base) + 10(service_retry.sh) = 100, monitor reset retry time to 0 forcely, 
and service retry times detecting script  "service_retry.sh" return 0 and adding it's weight 10. if service is active now, stop it.

  when one side has vip, if service is active,  the vrrp prior is 90(base) + 10(service_retry.sh) + 10(service_check.sh) = 110.
if service is not active, service start retry times great then retry times, vrrp prior is 90, and then other side now is 100(vip lost status), 
vip hand over immediately, after that this node lost vip,  vrrp prior of this node go back 100 right now.


配置 （var.sh):
ka_service_start_duration  : 业务启动完成等待时间，取值范围 [1,10]，默认值 1。
ka_retry_times : 业务启动持续失败次数，超过该次数，keepalived将移交vip到对端节点，取值范围 [1,5]，默认值 3。

工作原理 ：

  当一边丢失VIP之后，VRRP优先级应该是90(base) + 10(service_retry.sh) = 100，因为monitor将会强置重置retry time为0，
业务重试次数脚本service_retry.sh返回0，并将weight 10加上去，如果服务还处于active的话，将会停止它。

  当一边占用VIP，如果业务处于active状态，则vrrp priorty为  90(base) + 10(service_retry.sh) + 10(service_check.sh) = 110.
如果业务处于非active状态，业务重试次数大于最大重试次数，VRRP优先级是90，同时当前对端的为100(vip 丢失状态），
vip会立即移交到对端，之后当前节点就丢失VIP了，VRRP优先级回到100。

  如果两边的 vrrp prior 值相同，则不发生任何切换vip动作，只有在有vip一端的值比无vip一端的值小的时候，vip将会发生移交切换。