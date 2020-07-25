
	.286
	.model small
	.dosseg
	.stack 2048

DGROUP group _TEXT

lf	equ 10

CStr macro text:vararg
local sym
	.const
sym  db text,0
	.code
	exitm <offset sym>
endm

DStr macro text:vararg
local sym
	.const
sym  db text,0
	.data
	exitm <offset sym>
endm

	.data

msrs label dword
	dd 10h
	dd 1Bh
	dd 0e7h,0e8h
	dd 0feh
	dd 174h,175h,176h
	dd 179h,17ah,17bh
	dd 1D9h
	dd 1DBh,1DCh,1DDh,1DEh

	dd 200h,201h,202h,203h
	dd 204h,205h,206h,207h
	dd 208h,209h,20ah,20bh
	dd 20ch,20dh,20eh,20fh

	dd 250h,258h,259h
	dd 268h,269h,26Ah,26bh
	dd 26ch,26dh,26eh,26fh
	dd 277h
	dd 2ffh

	dd 0C0000080h,0C0000081h,0C0000082h,0C0000083h,0C0000084h
	dd 0C0000100h,0C0000101h,0C0000102h
	dd 0C0001019h,0C000101Ah,0C000101Bh,0C0001027h	;DRX_ADDR_MASK
	dd 0C0010010h	;SYSCFG
	dd 0C001001Ah
	dd 0C001001Bh
	dd 0C0010030h, 0C0010031h, 0C0010032h
	dd 0C0010033h, 0C0010034h, 0C0010035h
	dd 0C0010111h, 0C0010112h, 0C0010113h	;SMBASE, SMM_ADDR, SMM_MASK
	dd 0C0010114h, 0C0010115h, 0C0010116h	;VM_CR, IGNNE, SMM_CTL
	dd 0C0010117h, 0C0010118h, 0C0010119h	;VM_HSAVE_PA, SVM_KEY_MSR, SMM_KEY_MSR
	dd 0

names label word
	dw DStr("TSC")
	dw DStr("APIC Base Addr Register")
	dw DStr("MPERF"), DStr("APERF")
	dw DStr("MTRRCap")
	dw DStr("SysEnterCS"),DStr("SysEnterESP"),DStr("SysEnterEIP")
	dw DStr("MCG_Cap"),DStr("MCG_Status"),DStr("MCG_Ctl")
	dw DStr("DebugCtl")
	dw DStr("LastBranchFromIP"),DStr("LastBranchToIP"),DStr("LastIntFromIP"),DStr("LastIntToIP")

	dw DStr("MtrrBase0"),DStr("MtrrMask0"),DStr("MtrrBase1"),DStr("MtrrMask1")
	dw DStr("MtrrBase2"),DStr("MtrrMask2"),DStr("MtrrBase3"),DStr("MtrrMask3")
	dw DStr("MtrrBase4"),DStr("MtrrMask4"),DStr("MtrrBase5"),DStr("MtrrMask5")
	dw DStr("MtrrBase6"),DStr("MtrrMask6"),DStr("MtrrBase7"),DStr("MtrrMask8")

	dw DStr("MtrrFix64k_00000"),DStr("MtrrFix16k_80000"),DStr("MtrrFix16k_A0000")
	dw DStr("MtrrFix4k_C0000"),DStr("MtrrFix4k_C8000"),DStr("MtrrFix4k_D0000"),DStr("MtrrFix4k_D8000")
	dw DStr("MtrrFix4k_E0000"),DStr("MtrrFix4k_E8000"),DStr("MtrrFix4k_F0000"),DStr("MtrrFix4k_F8000")
	dw DStr("PAT")
	dw DStr("MtrrdefType")

	dw DStr("EFER"),DStr("STAR"),DStr("LSTAR"),DStr("CSTAR"),DStr("FMASK")
	dw DStr("FSBase"),DStr("GSBase"),DStr("KrnlGSBase")
	dw DStr("DR1_ADDR_MASK"),DStr("DR2_ADDR_MASK"),DStr("DR3_ADDR_MASK"),DStr("DR0_ADDR_MASK")
	dw DStr("SYSCFG")
	dw DStr("TOP_MEM")
	dw DStr("TOP_MEM2")
	dw DStr("CpuNameString"),DStr("CpuNameString"),DStr("CpuNameString")
	dw DStr("CpuNameString"),DStr("CpuNameString"),DStr("CpuNameString")
	dw DStr("SMBASE"),DStr("SMM_ADDR"), DStr("SMM_MASK")
	dw DStr("VM_CR"),DStr("IGNNE"), DStr("SMM_CTL")
	dw DStr("VM_HSAVE_PA"),DStr("SVM_KEY_MSR"), DStr("SMM_KEY_MSR")

orgint0d dw offset exc0D,seg exc0D
wSP	dw 0

	.code

	assume ds:DGROUP

	.386
	include printf.inc

	.586p

exc0D proc far
	sti
	pop ax
	pop dx
	cmp ax,msrlbl
	jz @F
	invoke printf, CStr(<"Exc 0Dh occured, cs:ip=%X:%X, ecx=%lX",lf>),dx,ax,ecx
	mov sp,wSP
	jmp done
@@:
	invoke printf, CStr(<"%lX(%s): undefined (access caused an Exc 0Dh)",lf>),ecx,bx
	mov sp,wSP
	jmp nextitem

exc0D endp

xchgint0d proc
	push 0
	pop es
	mov eax,dword ptr [orgint0d]
	xchg eax,es:[4*0Dh]
	mov dword ptr orgint0d,eax
	ret
xchgint0d endp

main proc
	mov wSP,sp
	smsw ax
	test al,1
	jz @F
	invoke printf,CStr(<"cannot run in V86 mode.",lf>)
	jmp exit
@@:
	call xchgint0d
	mov si,offset msrs
	mov di,offset names
nextitem::
	lodsd
	and eax,eax
	jz done
	mov ecx,eax
	xchg di,si
	lodsw
	mov bx,ax
	xchg di,si
msrlbl::
	rdmsr
	invoke printf, CStr(<"%lX(%s): %08lX-%08lX",lf>),ecx,bx,edx,eax
	jmp nextitem
done::
	call xchgint0d
exit:
	ret
main endp

start:
	push cs
	pop ds
	mov ax,ss
	mov dx,cs
	sub ax,dx
	shl ax,4
	push cs
	pop ss
	add sp,ax
	call main
	mov ax,4c00h
	int 21h

	end start

